defmodule CadetWeb.DevicesController do
  use CadetWeb, :controller

  use PhoenixSwagger

  alias Cadet.{Devices, DisplayHelper}
  alias Cadet.Devices.Device

  def index(conn, _params) do
    render(conn, "index.json",
      registrations: Devices.get_user_registrations(conn.assigns.current_user)
    )
  end

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

  def get_client_id(conn, %{"secret" => secret}) do
    case Devices.get_device(secret) do
      %Device{id: id} -> text(conn, Devices.get_thing_name(id))
      nil -> send_resp(conn, :not_found, "Device not found")
    end
  end

  @spec get_mqtt_endpoint(Plug.Conn.t(), any) :: Plug.Conn.t()
  def get_mqtt_endpoint(conn, _params) do
    # we have the secret but we don't check it currently
    {:ok, endpoint} = Devices.get_endpoint_address()
    text(conn, endpoint)
  end

  swagger_path :index do
    get("/devices")

    summary("Returns the devices registered by the user")

    security([%{JWT: []}])

    produces("application/json")

    response(200, "OK", Schema.array(:Device))
    response(401, "Unauthorised")
  end

  swagger_path :register do
    post("/devices")

    summary("Registers a new device")

    security([%{JWT: []}])

    consumes("application/json")
    produces("application/json")

    parameters do
      device(
        :body,
        Schema.ref(:RegisterDevicePayload),
        "Device details",
        required: true
      )
    end

    response(200, "OK", Schema.ref(:Device))
    response(400, "Conflicting device type or missing or invalid parameters")
    response(401, "Unauthorised")
  end

  swagger_path :edit do
    post("/devices/{id}")

    summary("Edits the given device")

    security([%{JWT: []}])

    consumes("application/json")

    parameters do
      id(:path, :integer, "Device ID", required: true)
      device(:body, Schema.ref(:EditDevicePayload), "Device details", required: true)
    end

    response(204, "OK")
    response(400, "Missing or invalid parameters")
    response(401, "Unauthorised")
    response(404, "Device not found")
  end

  swagger_path :deregister do
    PhoenixSwagger.Path.delete("/devices/{id}")

    summary("Unregisters the given device")

    security([%{JWT: []}])

    consumes("application/json")

    parameters do
      id(:path, :integer, "Device ID", required: true)
    end

    response(204, "OK")
    response(401, "Unauthorised")
    response(404, "Device not found")
  end

  swagger_path :get_ws_endpoint do
    get("/devices/{id}/ws_endpoint")

    summary("Generates a WebSocket endpoint URL for the given device")

    security([%{JWT: []}])

    produces("application/json")

    parameters do
      id(:path, :integer, "Device ID", required: true)
    end

    response(200, "OK", Schema.ref(:WebSocketEndpoint))
    response(401, "Unauthorised")
    response(404, "Device not found")
  end

  swagger_path :get_cert do
    get("/devices/{secret}/cert")

    summary("Returns the device's PEM-encoded client certificate")

    produces("text/plain")

    parameters do
      secret(:path, :string, "Device secret", required: true)
    end

    response(200, "OK", %PhoenixSwagger.Schema{type: :string})
    response(404, "Device not found")
  end

  swagger_path :get_key do
    get("/devices/{secret}/key")

    summary("Returns the device's PEM-encoded client key")

    produces("text/plain")

    parameters do
      secret(:path, :string, "Device secret", required: true)
    end

    response(200, "OK", %PhoenixSwagger.Schema{type: :string})
    response(404, "Device not found")
  end

  swagger_path :get_client_id do
    get("/devices/{secret}/client_id")

    summary("Returns the device's MQTT client ID")

    produces("text/plain")

    parameters do
      secret(:path, :string, "Device secret", required: true)
    end

    response(200, "OK", %PhoenixSwagger.Schema{type: :string})
    response(404, "Device not found")
  end

  swagger_path :get_mqtt_endpoint do
    get("/devices/{secret}/mqtt_endpoint")

    summary("Returns the MQTT endpoint the device should connect to")

    produces("text/plain")

    parameters do
      secret(:path, :string, "Device secret", required: true)
    end

    response(200, "OK", %PhoenixSwagger.Schema{type: :string})
    response(404, "Device not found")
  end

  def swagger_definitions do
    %{
      Device:
        swagger_schema do
          properties do
            id(:integer, "Device ID (unique to user)", required: true)
            type(:string, "User type", required: true)
            title(:string, "User-given device title", required: true)
            secret(:string, "Device unique secret", required: true)
          end
        end,
      WebSocketEndpoint:
        swagger_schema do
          properties do
            endpoint(:string, "Endpoint URL", required: true)
            clientNamePrefix(:string, "Client name prefix to use", required: true)
            thingName(:string, "Device name", required: true)
          end
        end,

      # Schemas for payloads to modify data
      RegisterDevicePayload:
        swagger_schema do
          properties do
            type(:string, "User type", required: true)
            title(:string, "User-given device title", required: true)
            secret(:string, "Device unique secret", required: true)
          end
        end,
      EditDevicePayload:
        swagger_schema do
          properties do
            title(:string, "User-given device title", required: true)
          end
        end
    }
  end
end
