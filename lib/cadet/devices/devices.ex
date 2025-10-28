defmodule Cadet.Devices do
  @moduledoc """
  Contains domain logic for remote execution devices.
  """
  use Cadet, [:context, :display]

  import Ecto.Query
  require Logger

  alias Cadet.AwsHelper
  alias Cadet.Accounts.User
  alias Cadet.Devices.{Device, DeviceRegistration}
  alias ExAws.STS

  @spec get_user_registrations(integer | String.t() | User.t()) :: [DeviceRegistration.t()]
  def get_user_registrations(%User{id: user_id}) do
    get_user_registrations(user_id)
  end

  def get_user_registrations(user_id) when is_ecto_id(user_id) do
    Logger.info("Retrieving device registrations for user #{user_id}")

    registrations =
      DeviceRegistration
      |> where(user_id: ^user_id)
      |> preload(:device)
      |> Repo.all()

    Logger.info("Retrieved #{length(registrations)} device registrations for user #{user_id}")
    registrations
  end

  @spec get_user_registration(integer | String.t() | User.t(), integer | String.t()) ::
          DeviceRegistration.t() | nil
  def get_user_registration(%User{id: user_id}, id) do
    get_user_registration(user_id, id)
  end

  def get_user_registration(user_id, id)
      when is_ecto_id(user_id) and is_ecto_id(id) do
    Logger.info("Retrieving device registration #{id} for user #{user_id}")

    registration =
      DeviceRegistration
      |> preload(:device)
      |> where(user_id: ^user_id)
      |> Repo.get(id)

    case registration do
      nil -> Logger.error("Device registration #{id} not found for user #{user_id}")
      _ -> Logger.info("Successfully retrieved device registration #{id} for user #{user_id}")
    end

    registration
  end

  @spec delete_registration(DeviceRegistration.t()) :: {:ok, DeviceRegistration.t()}
  def delete_registration(registration = %DeviceRegistration{}) do
    Logger.info(
      "Deleting device registration #{registration.id} for user #{registration.user_id}"
    )

    result = Repo.delete(registration)

    case result do
      {:ok, _} ->
        Logger.info("Successfully deleted device registration #{registration.id}")

      {:error, changeset} ->
        Logger.error(
          "Failed to delete device registration #{registration.id}: #{full_error_messages(changeset)}"
        )
    end

    result
  end

  @spec rename_registration(DeviceRegistration.t(), String.t()) ::
          {:ok, DeviceRegistration.t()} | {:error, Ecto.Changeset.t()}
  def rename_registration(registration = %DeviceRegistration{}, title) do
    Logger.info("Renaming device registration #{registration.id} to '#{title}'")

    result =
      registration
      |> DeviceRegistration.changeset(%{title: title})
      |> Repo.update()

    case result do
      {:ok, _} ->
        Logger.info("Successfully renamed device registration #{registration.id}")

      {:error, changeset} ->
        Logger.error(
          "Failed to rename device registration #{registration.id}: #{full_error_messages(changeset)}"
        )
    end

    result
  end

  @spec get_device(binary | integer) :: Device.t() | nil
  def get_device(device_id) when is_integer(device_id) do
    Repo.get(Device, device_id)
  end

  def get_device(device_secret) when is_binary(device_secret) do
    Device
    |> where(secret: ^device_secret)
    |> Repo.one()
  end

  @spec register(binary, binary, binary, integer | User.t()) ::
          {:ok, DeviceRegistration.t()} | {:error, Ecto.Changeset.t() | :conflicting_device}
  def register(title, type, secret, %User{id: user_id}) do
    register(title, type, secret, user_id)
  end

  def register(title, type, secret, user_id)
      when is_binary(title) and is_binary(type) and is_binary(secret) and is_integer(user_id) do
    with {:ok, device} <- maybe_insert_device(type, secret),
         {:ok, registration} <-
           %DeviceRegistration{}
           |> DeviceRegistration.changeset(%{
             user_id: user_id,
             device_id: device.id,
             title: title
           })
           |> Repo.insert() do
      {:ok, registration |> Repo.preload(:device)}
    end
  end

  @spec get_device_key_cert(binary | integer | Device.t()) ::
          {:ok, {String.t(), String.t()}}
          | {:error,
             :no_such_device
             | {:http_error, number, map}
             | Jason.DecodeError.t()
             | Jason.EncodeError.t()
             | Ecto.Changeset.t()}
  def get_device_key_cert(%Device{client_key: key, client_cert: cert})
      when not is_nil(key) and not is_nil(cert) do
    {:ok, {key, cert}}
  end

  def get_device_key_cert(device = %Device{id: id, client_key: nil, client_cert: nil}) do
    with {:ok, {key, cert}} <- create_device_key_cert(id),
         {:ok, _} <-
           device |> Device.changeset(%{client_key: key, client_cert: cert}) |> Repo.update() do
      {:ok, {key, cert}}
    end
  end

  def get_device_key_cert(device_id_or_secret)
      when is_integer(device_id_or_secret) or is_binary(device_id_or_secret) do
    case get_device(device_id_or_secret) do
      nil -> {:error, :no_such_device}
      device -> get_device_key_cert(device)
    end
  end

  @spec maybe_insert_device(binary, binary) ::
          {:ok, Device.t()} | {:error, Ecto.Changeset.t() | :conflicting_device}
  defp maybe_insert_device(type, secret) do
    case get_device(secret) do
      device = %Device{} ->
        if(device.type == type and device.secret == secret,
          do: {:ok, device},
          else: {:error, :conflicting_device}
        )

      nil ->
        %Device{} |> Device.changeset(%{type: type, secret: secret}) |> Repo.insert()
    end
  end

  @spec create_device_key_cert(integer) ::
          {:error,
           :no_such_device
           | {:http_error, number, map}
           | Jason.DecodeError.t()
           | Jason.EncodeError.t()}
          | {:ok, {String.t(), String.t()}}
  defp create_device_key_cert(device_id) do
    thing_name = get_thing_name(device_id)

    with {:make_cert, {:ok, %{body: cert}}} <-
           {:make_cert, do_awsiot_request(:post, "/keys-and-certificate?setAsActive=true")},
         {:attach_thing, {:ok, _}} <-
           {:attach_thing, maybe_create_thing_and_attach_cert(thing_name, cert["certificateArn"])} do
      {:ok, {cert["keyPair"]["PrivateKey"], cert["certificatePem"]}}
    else
      {_, e = {:error, _}} -> e
    end
  end

  defp maybe_create_thing_and_attach_cert(thing_name, cert_arn, retry \\ false) do
    case {do_awsiot_request(:put, "/things/#{thing_name}/principals", [
            {"x-amzn-principal", cert_arn}
            # hack so that we can differentiate these two requests in ExVCR :/
            | if(Cadet.Env.env() == :test,
                do: [{"x-different-request", Atom.to_string(retry)}],
                else: []
              )
          ]), retry} do
      {{:error, {:http_error, 404, _}}, false} ->
        with {:ok, _} <- do_awsiot_json_request(:post, "/things/#{thing_name}", %{}),
             {:ok, _} <-
               do_awsiot_json_request(:put, "/thing-groups/addThingToThingGroup", %{
                 "thingName" => thing_name,
                 "thingGroupName" => aws_thing_group()
               }) do
          maybe_create_thing_and_attach_cert(thing_name, cert_arn, true)
        end

      {result, _} ->
        result
    end
  end

  @spec get_device_ws_endpoint(
          binary | integer | Device.t(),
          User.t(),
          [{:datetime, :calendar.datetime()}]
        ) ::
          {:ok, %{}}
          | {:error,
             :no_such_device
             | {:http_error, number, map}
             | Jason.DecodeError.t()
             | Jason.EncodeError.t()}
  def get_device_ws_endpoint(device_or_id_or_secret, user, opts \\ [])

  def get_device_ws_endpoint(device_id_or_secret, user = %User{}, opts)
      when is_integer(device_id_or_secret) or is_binary(device_id_or_secret) do
    case get_device(device_id_or_secret) do
      nil -> {:error, :no_such_device}
      device -> get_device_ws_endpoint(device, user, opts)
    end
  end

  def get_device_ws_endpoint(%Device{id: device_id}, %User{id: user_id}, opts) do
    case Keyword.get(config(), :ws_endpoint_address) do
      nil ->
        with {:ok, address} <- get_endpoint_address(),
             {:ok, %{body: creds}} <- get_temporary_token(device_id, user_id) do
          uri = URI.to_string(%URI{scheme: "wss", host: address, path: "/mqtt"})
          region = Application.fetch_env!(:ex_aws, :region)

          {:ok, signed_url} =
            ExAws.Auth.presigned_url(
              :get,
              uri,
              :iotdevicegateway,
              Keyword.get(opts, :datetime) || :calendar.universal_time(),
              %{
                region: region,
                access_key_id: creds.access_key_id,
                secret_access_key: creds.secret_access_key
              },
              300,
              [],
              ""
            )

          # ExAws includes the session token in the signed payload and doesn't allow
          # you not to do so. Some AWS services require it to be in the signed
          # payload, some don't. This one doesn't, so.. we manually append the
          # security token. *sigh*
          {:ok,
           %{
             endpoint:
               "#{signed_url}&X-Amz-Security-Token=#{URI.encode_www_form(creds.session_token)}",
             thing_name: get_thing_name(device_id),
             client_name_prefix: get_ws_client_prefix(user_id)
           }}
        end

      address ->
        {:ok,
         %{
           endpoint: address,
           thing_name: get_thing_name(device_id),
           client_name_prefix: get_ws_client_prefix(user_id)
         }}
    end
  end

  def get_endpoint_address do
    case Keyword.get(config(), :endpoint_address) do
      nil ->
        case do_awsiot_request(:get, "/endpoint?endpointType=iot:Data-ATS") do
          {:ok, %{body: %{"endpointAddress" => address}}} ->
            new_config = Keyword.put(config(), :endpoint_address, address)
            Application.put_env(:cadet, :remote_execution, new_config)

            {:ok, address}

          error = {:error, _} ->
            error
        end

      address ->
        {:ok, address}
    end
  end

  defp get_temporary_token(device_id, user_id) do
    r =
      STS.assume_role(
        aws_client_role_arn(),
        "#{aws_thing_prefix()}-d#{device_id}-u#{user_id}"
      )

    policy =
      Jason.encode!(%{
        "Version" => "2012-10-17",
        "Statement" => [
          %{
            "Sid" => "Stmt0",
            "Effect" => "Allow",
            "Action" => [
              "iot:Receive",
              "iot:Subscribe",
              "iot:Connect",
              "iot:Publish"
            ],
            "Resource" => [
              "arn:aws:iot:*:*:topicfilter/#{get_thing_name(device_id)}/*",
              "arn:aws:iot:*:*:topic/#{get_thing_name(device_id)}/*",
              "arn:aws:iot:*:*:client/#{get_ws_client_prefix(user_id)}*"
            ]
          }
        ]
      })

    r
    |> Map.update!(:params, &Map.put(&1, "Policy", policy))
    |> ExAws.request()
  end

  def get_thing_name(device_id) do
    "#{aws_thing_prefix()}:#{device_id}"
  end

  defp do_awsiot_request(method, path, headers \\ []) do
    do_awsiot_operation(
      %ExAws.Operation.RestQuery{
        http_method: method,
        path: path
      },
      headers
    )
  end

  defp do_awsiot_json_request(method, path, body, headers \\ []) do
    with {:ok, body} <- Jason.encode(body) do
      do_awsiot_operation(
        %ExAws.Operation.RestQuery{
          http_method: method,
          path: path,
          body: body
        },
        [{"Content-Type", "application/json"} | headers]
      )
    end
  end

  defp do_awsiot_operation(request = %ExAws.Operation.RestQuery{}, headers) do
    request
    |> Map.merge(%{parser: &decode_awsiot_response/2, service: :iot})
    # ex_aws bug, sigh
    |> AwsHelper.request(headers, service_override: :"execute-api")
  end

  defp decode_awsiot_response({:ok, payload}, _) do
    case String.trim(payload.body) do
      "" ->
        {:ok, nil}

      trimmed_body ->
        with {:ok, body} <- Jason.decode(trimmed_body) do
          {:ok, Map.put(payload, :body, body)}
        end
    end
  end

  defp decode_awsiot_response(e = {:error, _}, _) do
    e
  end

  defp get_ws_client_prefix(user_id) do
    "#{aws_thing_prefix()}-u#{user_id}-"
  end

  defp aws_thing_prefix do
    Keyword.fetch!(config(), :thing_prefix)
  end

  defp aws_thing_group do
    Keyword.fetch!(config(), :thing_group)
  end

  defp aws_client_role_arn do
    Keyword.fetch!(config(), :client_role_arn)
  end

  defp config do
    Application.fetch_env!(:cadet, :remote_execution)
  end
end
