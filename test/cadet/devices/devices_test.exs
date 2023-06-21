defmodule Cadet.DevicesTest do
  use Cadet.DataCase

  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Cadet.{Devices, Repo}
  alias Cadet.Devices.DeviceRegistration

  @registration_compare_fields ~w(id title device_id user_id)a

  setup do
    user = insert(:user)
    device = insert(:device, client_key: nil, client_cert: nil)

    new_config =
      :cadet
      |> Application.get_env(:remote_execution)
      |> Keyword.delete(:ws_endpoint_address)
      # Transitive dependency on endpoint_address
      # Needs to be removed in order to use mocked responses
      |> Keyword.delete(:endpoint_address)

    Application.put_env(:cadet, :remote_execution, new_config)

    {:ok, registration} =
      Repo.insert(%DeviceRegistration{
        title: "Test device",
        device_id: device.id,
        user_id: user.id
      })

    {:ok, %{user: user, device: device, registration: registration}}
  end

  test "get registrations by user id", %{user: user, registration: registration} do
    results = Devices.get_user_registrations(user.id)

    assert_submaps_eq(results, [registration], @registration_compare_fields)
  end

  test "get registrations by user", %{user: user, registration: registration} do
    results = Devices.get_user_registrations(user)

    assert_submaps_eq(results, [registration], @registration_compare_fields)
  end

  test "get registration by user id and id", %{user: user, registration: registration} do
    assert_submap_eq(
      Devices.get_user_registration(user.id, registration.id),
      registration,
      @registration_compare_fields
    )
  end

  test "get registration by user and id", %{user: user, registration: registration} do
    assert_submap_eq(
      Devices.get_user_registration(user, registration.id),
      registration,
      @registration_compare_fields
    )
  end

  test "get device by id", %{device: device} do
    assert Devices.get_device(device.id) == device
  end

  test "get device by secret", %{device: device} do
    assert Devices.get_device(device.secret) == device
  end

  test "delete registration", %{registration: registration} do
    assert {:ok, _} = Devices.delete_registration(registration)

    assert is_nil(Repo.get(DeviceRegistration, registration.id))
  end

  test "add existing device to new user", %{device: device} do
    user = insert(:user)
    title = Faker.Person.En.first_name()

    assert {:ok, %DeviceRegistration{} = registration} =
             Devices.register(title, device.type, device.secret, user.id)

    assert title === registration.title
    assert user.id === registration.user_id
    assert device.id === registration.device_id
  end

  test "add new device to user", %{user: user} do
    type = Faker.Person.En.first_name()
    title = Faker.Person.En.first_name()
    secret = Faker.UUID.v4()

    assert {:ok, %DeviceRegistration{} = registration} =
             Devices.register(title, type, secret, user.id)

    assert title === registration.title
    assert user.id === registration.user_id

    assert registration.device.id === registration.device_id
    assert type === registration.device.type
    assert secret === registration.device.secret
  end

  test "add conflicting device should fail", %{user: user, device: device} do
    assert {:error, :conflicting_device} =
             Devices.register("Test title", device.type <> "x", device.secret, user.id)
  end

  test "get certificate for new device", %{device: device} do
    use_cassette "aws/devices_get_cert#1",
      custom_matchers: [&match_different_request/3],
      custom: true do
      assert {:ok, {"key", "cert"}} == Devices.get_device_key_cert(device)
    end
  end

  test "get certificate for existing device", %{device: device} do
    use_cassette "aws/devices_get_cert#2", custom: true do
      assert {:ok, {"key", "cert"}} == Devices.get_device_key_cert(device)
    end
  end

  test "get certificate by device id", %{device: device} do
    use_cassette "aws/devices_get_cert#2", custom: true do
      assert {:ok, {"key", "cert"}} == Devices.get_device_key_cert(device.id)
    end
  end

  test "get certificate by device secret", %{device: device} do
    use_cassette "aws/devices_get_cert#2", custom: true do
      assert {:ok, {"key", "cert"}} == Devices.get_device_key_cert(device.secret)
    end
  end

  test "get certificate error", %{device: device} do
    use_cassette "aws/devices_get_cert#3", custom: true do
      assert {:error, _} = Devices.get_device_key_cert(device)
    end
  end

  test "get endpoint returns address" do
    use_cassette "aws/devices_get_endpoint_address#1", custom: true do
      assert {:ok, "test-ats.iot.ap-southeast-1.amazonaws.com"} = Devices.get_endpoint_address()
    end
  end

  test "get endpoint updates environment" do
    use_cassette "aws/devices_get_endpoint_address#1", custom: true do
      old_config =
        :cadet
        |> Application.get_env(:remote_execution)

      assert nil == Keyword.get(old_config, :endpoint_address)

      {:ok, address} = Devices.get_endpoint_address()

      updated_config =
        :cadet
        |> Application.get_env(:remote_execution)

      assert ^address = Keyword.get(updated_config, :endpoint_address)
    end
  end

  test "get endpoint can be overridden using config" do
    use_cassette "aws/devices_get_endpoint_address#1", custom: true do
      new_config =
        :cadet
        |> Application.get_env(:remote_execution)
        |> Keyword.put(:endpoint_address, "localhost:1883")

      Application.put_env(:cadet, :remote_execution, new_config)

      assert {:ok, "localhost:1883"} = Devices.get_endpoint_address()
    end
  end

  test "get ws endpoint by device id", %{device: device, user: user} do
    use_cassette "aws/devices_get_ws_endpoint#1", custom: true do
      assert {
               :ok,
               %{
                 client_name_prefix: _,
                 endpoint:
                   "wss://test-ats.iot.ap-southeast-1.amazonaws.com/mqtt?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=ASIATESTTEST%2F20200101%2Fap-southeast-1%2Fiotdevicegateway%2Faws4_request&X-Amz-Date=20200101T123456Z&X-Amz-Expires=300&X-Amz-SignedHeaders=host&X-Amz-Signature=49cc00fa6d52ad194bc9d63997bbbda4f6cac9c3f838ec3970fed65748550940&X-Amz-Security-Token=IOTESTTESTTEST",
                 thing_name: _
               }
             } =
               Devices.get_device_ws_endpoint(device.id, user,
                 datetime: {{2020, 01, 01}, {12, 34, 56}}
               )
    end
  end

  test "get ws endpoint by device secret", %{device: device, user: user} do
    use_cassette "aws/devices_get_ws_endpoint#1", custom: true do
      assert {
               :ok,
               %{
                 client_name_prefix: _,
                 endpoint:
                   "wss://test-ats.iot.ap-southeast-1.amazonaws.com/mqtt?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=ASIATESTTEST%2F20200101%2Fap-southeast-1%2Fiotdevicegateway%2Faws4_request&X-Amz-Date=20200101T123456Z&X-Amz-Expires=300&X-Amz-SignedHeaders=host&X-Amz-Signature=49cc00fa6d52ad194bc9d63997bbbda4f6cac9c3f838ec3970fed65748550940&X-Amz-Security-Token=IOTESTTESTTEST",
                 thing_name: _
               }
             } =
               Devices.get_device_ws_endpoint(device.secret, user,
                 datetime: {{2020, 01, 01}, {12, 34, 56}}
               )
    end
  end

  test "get ws endpoint by device", %{device: device, user: user} do
    use_cassette "aws/devices_get_ws_endpoint#1", custom: true do
      assert {
               :ok,
               %{
                 client_name_prefix: _,
                 endpoint:
                   "wss://test-ats.iot.ap-southeast-1.amazonaws.com/mqtt?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=ASIATESTTEST%2F20200101%2Fap-southeast-1%2Fiotdevicegateway%2Faws4_request&X-Amz-Date=20200101T123456Z&X-Amz-Expires=300&X-Amz-SignedHeaders=host&X-Amz-Signature=49cc00fa6d52ad194bc9d63997bbbda4f6cac9c3f838ec3970fed65748550940&X-Amz-Security-Token=IOTESTTESTTEST",
                 thing_name: _
               }
             } =
               Devices.get_device_ws_endpoint(
                 device,
                 user,
                 datetime: {{2020, 01, 01}, {12, 34, 56}}
               )
    end
  end

  test "get ws endpoint can be overridden using config", %{device: device, user: user} do
    use_cassette "aws/devices_get_ws_endpoint#1", custom: true do
      new_config =
        :cadet
        |> Application.get_env(:remote_execution)
        |> Keyword.put(:ws_endpoint_address, "ws://localhost:9001")
        # Transitive dependency on endpoint_address
        # Needs to be removed in order to use mocked responses
        |> Keyword.delete(:endpoint_address)

      Application.put_env(:cadet, :remote_execution, new_config)

      assert {
               :ok,
               %{
                 client_name_prefix: _,
                 endpoint: "ws://localhost:9001",
                 thing_name: _
               }
             } = Devices.get_device_ws_endpoint(device.id, user)
    end
  end

  test "get ws endpoint, error on get endpoint", %{device: device, user: user} do
    use_cassette "aws/devices_get_ws_endpoint#2", custom: true do
      new_config =
        :cadet
        |> Application.get_env(:remote_execution)
        |> Keyword.delete(:endpoint_address)
        # Delete to ensure we are testing non-overridden config
        |> Keyword.delete(:ws_endpoint_address)

      Application.put_env(:cadet, :remote_execution, new_config)

      assert {:error, _} = Devices.get_device_ws_endpoint(device.id, user)
    end
  end

  test "get ws endpoint, error on assume role", %{device: device, user: user} do
    use_cassette "aws/devices_get_ws_endpoint#3", custom: true do
      assert {:error, _} = Devices.get_device_ws_endpoint(device.id, user)
    end
  end

  defp header_list_to_map(list) when is_list(list) do
    Enum.into(list, %{})
  end

  defp header_list_to_map(map = %{}) do
    map
  end

  defp match_different_request(response, keys, _) do
    recorded_headers = header_list_to_map(response.request.headers)
    this_headers = header_list_to_map(keys[:headers])

    recorded_headers["x-different-request"] == this_headers["x-different-request"]
  end
end
