defmodule CadetWeb.DevicesController do
  use CadetWeb, :controller
  use OpenApiSpex.ControllerSpecs

  # The secret-based device routes bypass the :api pipeline (no PutApiSpec), so
  # they cannot be validated by CastAndValidate.
  plug(
    OpenApiSpex.Plug.CastAndValidate,
    [render_error: CadetWeb.Plugs.OpenApiErrorRenderer, replace_params: false]
    when action not in [:get_cert, :get_key, :get_client_id, :get_mqtt_endpoint]
  )

  alias Cadet.{Devices, DisplayHelper}
  alias Cadet.Devices.Device
  alias CadetWeb.ApiSpec.ErrorResponses
  alias CadetWeb.Schemas
  alias OpenApiSpex.Schema

  tags(["Devices"])

  @jwt [%{"JWT" => []}]

  operation(:index,
    summary: "Get the devices registered by the current user",
    security: @jwt,
    responses: [
      ok: {"List of devices", "application/json", %Schema{type: :array, items: Schemas.Device}},
      unauthorized: ErrorResponses.unauthorised()
    ]
  )

  def index(conn, _params) do
    render(conn, "index.json",
      registrations: Devices.get_user_registrations(conn.assigns.current_user)
    )
  end

  operation(:register,
    summary: "Register a new device",
    security: @jwt,
    request_body: {"The device to register", "application/json", Schemas.RegisterDevicePayload},
    responses: [
      ok: {"The registered device", "application/json", Schemas.Device},
      bad_request: ErrorResponses.bad_request(),
      unauthorized: ErrorResponses.unauthorised()
    ]
  )

  def register(conn, %{"title" => title, "type" => type, "secret" => secret}) do
    case Devices.register(title, type, secret, conn.assigns.current_user) do
      {:ok, registration} ->
        render(conn, "show.json", registration: registration)

      {:error, :conflicting_device} ->
        send_resp(conn, :bad_request, "There is a device with the same secret but different type")

      {:error, changeset = %Ecto.Changeset{}} ->
        send_resp(conn, :bad_request, DisplayHelper.full_error_messages(changeset))
    end
  end

  operation(:edit,
    summary: "Edit the title of a registered device",
    security: @jwt,
    parameters: [id: [in: :path, type: :integer, required: true, description: "Device ID"]],
    request_body: {"The updated device details", "application/json", Schemas.EditDevicePayload},
    responses: [
      no_content: "Device updated",
      bad_request: ErrorResponses.bad_request(),
      unauthorized: ErrorResponses.unauthorised(),
      not_found: ErrorResponses.not_found()
    ]
  )

  def edit(conn, %{"id" => device_id, "title" => title}) do
    with {:get_registration, registration} when not is_nil(registration) <-
           {:get_registration,
            Devices.get_user_registration(conn.assigns.current_user, device_id)},
         {:rename, {:ok, _}} <- {:rename, Devices.rename_registration(registration, title)} do
      send_resp(conn, :no_content, "")
    else
      {:get_registration, nil} ->
        send_resp(conn, :not_found, "Registration not found")

      {:rename, {:error, changeset = %Ecto.Changeset{}}} ->
        send_resp(conn, :bad_request, DisplayHelper.full_error_messages(changeset))
    end
  end

  operation(:deregister,
    summary: "Unregister a device",
    security: @jwt,
    parameters: [id: [in: :path, type: :integer, required: true, description: "Device ID"]],
    responses: [
      no_content: "Device unregistered",
      unauthorized: ErrorResponses.unauthorised(),
      not_found: ErrorResponses.not_found()
    ]
  )

  def deregister(conn, %{"id" => device_id}) do
    with {:get_registration, registration} when not is_nil(registration) <-
           {:get_registration,
            Devices.get_user_registration(conn.assigns.current_user, device_id)},
         {:delete, {:ok, _}} <- {:delete, Devices.delete_registration(registration)} do
      send_resp(conn, :no_content, "")
    else
      {:get_registration, nil} ->
        send_resp(conn, :not_found, "Registration not found")
    end
  end

  operation(:get_ws_endpoint,
    summary: "Generate a WebSocket endpoint URL for a device",
    security: @jwt,
    parameters: [id: [in: :path, type: :integer, required: true, description: "Device ID"]],
    responses: [
      ok: {"The WebSocket endpoint", "application/json", Schemas.WebSocketEndpoint},
      unauthorized: ErrorResponses.unauthorised(),
      not_found: ErrorResponses.not_found(),
      internal_server_error: ErrorResponses.internal_server_error()
    ]
  )

  def get_ws_endpoint(conn, %{"id" => device_id}) do
    with {:get_registration, registration} when not is_nil(registration) <-
           {:get_registration,
            Devices.get_user_registration(conn.assigns.current_user, device_id)},
         {:get_ws_endpoint, {:ok, endpoint}} <-
           {:get_ws_endpoint,
            Devices.get_device_ws_endpoint(registration.device, conn.assigns.current_user)} do
      json(conn, camel_casify_atom_keys(endpoint))
    else
      {:get_registration, nil} ->
        send_resp(conn, :not_found, "Registration not found")

      {:get_ws_endpoint, error} ->
        send_sentry_error(error)

        send_resp(conn, :internal_server_error, "Upstream AWS error")
    end
  end

  # The following two handlers are almost identical
  # The reason they are separate is so we can avoid the devices having to parse
  # JSON

  operation(:get_cert,
    summary: "Get the device's PEM-encoded client certificate",
    parameters: [secret: [in: :path, type: :string, required: true, description: "Device secret"]],
    responses: [
      ok: {"The client certificate", "text/plain", %Schema{type: :string}},
      not_found: ErrorResponses.not_found(),
      internal_server_error: ErrorResponses.internal_server_error()
    ]
  )

  def get_cert(conn, %{"secret" => secret}) do
    case Devices.get_device_key_cert(secret) do
      {:ok, {_, cert}} ->
        text(conn, cert)

      {:error, :no_such_device} ->
        send_resp(conn, :not_found, "Device not found")

      {:error, error} ->
        send_sentry_error(error)

        send_resp(conn, :internal_server_error, "Upstream AWS error")
    end
  end

  operation(:get_key,
    summary: "Get the device's PEM-encoded client key",
    parameters: [secret: [in: :path, type: :string, required: true, description: "Device secret"]],
    responses: [
      ok: {"The client key", "text/plain", %Schema{type: :string}},
      not_found: ErrorResponses.not_found(),
      internal_server_error: ErrorResponses.internal_server_error()
    ]
  )

  def get_key(conn, %{"secret" => secret}) do
    case Devices.get_device_key_cert(secret) do
      {:ok, {key, _}} ->
        text(conn, key)

      {:error, :no_such_device} ->
        send_resp(conn, :not_found, "Device not found")

      {:error, error} ->
        send_sentry_error(error)

        send_resp(conn, :internal_server_error, "Upstream AWS error")
    end
  end

  operation(:get_client_id,
    summary: "Get the device's MQTT client id",
    parameters: [secret: [in: :path, type: :string, required: true, description: "Device secret"]],
    responses: [
      ok: {"The MQTT client id", "text/plain", %Schema{type: :string}},
      not_found: ErrorResponses.not_found()
    ]
  )

  def get_client_id(conn, %{"secret" => secret}) do
    case Devices.get_device(secret) do
      %Device{id: id} -> text(conn, Devices.get_thing_name(id))
      nil -> send_resp(conn, :not_found, "Device not found")
    end
  end

  operation(:get_mqtt_endpoint,
    summary: "Get the MQTT endpoint the device should connect to",
    parameters: [secret: [in: :path, type: :string, required: true, description: "Device secret"]],
    responses: [
      ok: {"The MQTT endpoint", "text/plain", %Schema{type: :string}}
    ]
  )

  @spec get_mqtt_endpoint(Plug.Conn.t(), any) :: Plug.Conn.t()
  def get_mqtt_endpoint(conn, _params) do
    # we have the secret but we don't check it currently
    {:ok, endpoint} = Devices.get_endpoint_address()
    text(conn, endpoint)
  end
end
