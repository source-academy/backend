defmodule DevicesControllerTest do
  use CadetWeb.ConnCase

  alias Cadet.{Devices, Repo}
  alias Cadet.Devices.{Device, DeviceRegistration}
  alias CadetWeb.DevicesController

  import Mock

  setup do
    device = insert(:device)
    %{device: device}
  end

  test "swagger" do
    DevicesController.swagger_definitions()
    DevicesController.swagger_path_index(nil)
    DevicesController.swagger_path_register(nil)
    DevicesController.swagger_path_edit(nil)
    DevicesController.swagger_path_deregister(nil)
    DevicesController.swagger_path_get_ws_endpoint(nil)
    DevicesController.swagger_path_get_cert(nil)
    DevicesController.swagger_path_get_key(nil)
    DevicesController.swagger_path_get_client_id(nil)
    DevicesController.swagger_path_get_mqtt_endpoint(nil)
  end

  describe "GET /devices" do
    @tag authenticate: :student
    test "succeeds if authenticated", %{conn: conn, device: device} do
      registration = insert_registration(conn, device)

      assert [
               %{
                 "id" => registration.id,
                 "secret" => device.secret,
                 "title" => registration.title,
                 "type" => device.type
               }
             ] ==
               conn
               |> get(build_url())
               |> json_response(200)
    end

    test "401 if unauthenticated", %{conn: conn} do
      assert conn
             |> get(build_url())
             |> response(401)
    end
  end

  describe "POST /devices" do
    @tag authenticate: :student
    test "succeeds if authenticated", %{conn: conn, device: device} do
      registration = make_json_registration(device)

      assert response =
               conn
               |> post(build_url(), registration)
               |> json_response(200)

      assert registration["title"] == response["title"]
      assert device.secret == response["secret"]
      assert device.type == response["type"]
    end

    @tag authenticate: :student
    test "fails if conflicting type", %{conn: conn, device: device} do
      registration = %{make_json_registration(device) | "type" => "installation 00"}

      assert conn
             |> post(build_url(), registration)
             |> response(400)
    end

    @tag authenticate: :student
    test "fails if invalid", %{conn: conn, device: device} do
      registration = %{make_json_registration(device) | "secret" => ""}

      assert conn
             |> post(build_url(), registration)
             |> response(400)
    end

    test "401 if unauthenticated", %{conn: conn, device: device} do
      registration = make_json_registration(device)

      assert conn
             |> post(build_url(), registration)
             |> response(401)
    end
  end

  describe "POST /devices/:id" do
    setup context, do: maybe_setup_registration(context)

    @tag authenticate: :student
    test "succeeds if authenticated", %{conn: conn, registration: registration} do
      new_title = Faker.Person.En.name()

      assert conn
             |> post(build_url(registration.id), %{"title" => new_title})
             |> response(204)

      new_registration = Devices.get_user_registration(conn.assigns.current_user, registration.id)

      assert new_title == new_registration.title
    end

    @tag authenticate: :student
    test "fails if nonexistent", %{conn: conn, registration: registration} do
      new_title = Faker.Person.En.name()

      assert conn
             |> post(build_url(registration.id + 1), %{"title" => new_title})
             |> response(404)
    end

    @tag authenticate: :student
    test "fails if invalid", %{conn: conn, registration: registration} do
      assert conn
             |> post(build_url(registration.id), %{"title" => ""})
             |> response(400)
    end

    test "401 if unauthenticated", %{conn: conn} do
      new_title = Faker.Person.En.name()

      assert conn
             |> post(build_url(123), %{"title" => new_title})
             |> response(401)
    end
  end

  describe "DELETE /devices/:id" do
    setup context, do: maybe_setup_registration(context)

    @tag authenticate: :student
    test "succeeds if authenticated", %{conn: conn, registration: registration} do
      assert conn
             |> delete(build_url(registration.id))
             |> response(204)

      assert is_nil(Devices.get_user_registration(conn.assigns.current_user, registration.id))
    end

    @tag authenticate: :student
    test "fails if nonexistent", %{conn: conn, registration: registration} do
      assert conn
             |> delete(build_url(registration.id + 1))
             |> response(404)
    end

    test "401 if unauthenticated", %{conn: conn} do
      assert conn
             |> delete(build_url(123))
             |> response(401)
    end
  end

  describe "GET /devices/:id/ws_endpoint" do
    setup context, do: maybe_setup_registration(context)

    @tag authenticate: :student
    test_with_mock "succeeds if authenticated",
                   %{conn: conn, device: device, registration: registration},
                   Devices,
                   [],
                   get_user_registration: fn user, id ->
                     assert conn.assigns.current_user.id == user.id
                     assert to_string(id) == to_string(registration.id)

                     %{registration | device: device}
                   end,
                   get_device_ws_endpoint: fn %Device{id: device_id}, user ->
                     assert device.id == device_id
                     assert conn.assigns.current_user.id == user.id

                     {:ok,
                      %{
                        endpoint: "fake_endpoint",
                        thing_name: "thing_name",
                        client_name_prefix: "client_name_prefix"
                      }}
                   end do
      assert %{
               "clientNamePrefix" => "client_name_prefix",
               "endpoint" => "fake_endpoint",
               "thingName" => "thing_name"
             } ==
               conn
               |> get(build_url(registration.id, "ws_endpoint"))
               |> json_response(200)
    end

    @tag authenticate: :student
    test_with_mock "handles AWS error gracefully",
                   %{conn: conn, device: device, registration: registration},
                   Devices,
                   [],
                   get_user_registration: fn user, id ->
                     assert conn.assigns.current_user.id == user.id
                     assert to_string(id) == to_string(registration.id)

                     %{registration | device: device}
                   end,
                   get_device_ws_endpoint: fn _, _ ->
                     {:error, "fake error"}
                   end do
      assert conn
             |> get(build_url(registration.id, "ws_endpoint"))
             |> response(500) =~ "Upstream AWS error"
    end

    @tag authenticate: :student
    test "fails if nonexistent", %{conn: conn, registration: registration} do
      assert conn
             |> get(build_url(registration.id + 1, "ws_endpoint"))
             |> response(404)
    end

    test "401 if unauthenticated", %{conn: conn} do
      assert conn
             |> get(build_url(123, "ws_endpoint"))
             |> response(401)
    end
  end

  describe "GET /devices/:secret/cert" do
    test "succeeds", %{conn: conn, device: device} do
      assert device.client_cert ==
               conn
               |> get(build_url(device.secret, "cert"))
               |> response(200)
    end

    test "fails if nonexistent", %{conn: conn, device: device} do
      assert conn
             |> get(build_url(device.secret <> "why_like_that", "cert"))
             |> response(404)
    end

    test_with_mock "handles AWS error gracefully",
                   %{conn: conn, device: device},
                   Devices,
                   [],
                   get_device_key_cert: fn secret ->
                     assert device.secret == secret

                     {:error, "fake error"}
                   end do
      assert conn
             |> get(build_url(device.secret, "cert"))
             |> response(500) =~ "Upstream AWS error"
    end
  end

  describe "GET /devices/:secret/key" do
    test "succeeds", %{conn: conn, device: device} do
      assert device.client_key ==
               conn
               |> get(build_url(device.secret, "key"))
               |> response(200)
    end

    test "fails if nonexistent", %{conn: conn, device: device} do
      assert conn
             |> get(build_url(device.secret <> "why_like_that", "key"))
             |> response(404)
    end

    test_with_mock "handles AWS error gracefully",
                   %{conn: conn, device: device},
                   Devices,
                   [],
                   get_device_key_cert: fn secret ->
                     assert device.secret == secret

                     {:error, "fake error"}
                   end do
      assert conn
             |> get(build_url(device.secret, "key"))
             |> response(500) =~ "Upstream AWS error"
    end
  end

  describe "GET /devices/:secret/client_id" do
    test "succeeds", %{conn: conn, device: device} do
      assert Devices.get_thing_name(device.id) ==
               conn
               |> get(build_url(device.secret, "client_id"))
               |> response(200)
    end

    test "fails if nonexistent", %{conn: conn, device: device} do
      assert conn
             |> get(build_url(device.secret <> "why_like_that", "client_id"))
             |> response(404)
    end
  end

  describe "GET /devices/:secret/mqtt_endpoint" do
    test_with_mock "succeeds",
                   %{conn: conn, device: device},
                   Devices,
                   [],
                   get_endpoint_address: fn ->
                     {:ok, "fake_endpoint"}
                   end do
      assert "fake_endpoint" ==
               conn
               |> get(build_url(device.secret, "mqtt_endpoint"))
               |> response(200)
    end
  end

  defp make_json_registration(device) do
    %{
      "title" => Faker.App.name(),
      "type" => device.type,
      "secret" => device.secret
    }
  end

  defp maybe_setup_registration(%{conn: conn, device: device}) do
    if Map.has_key?(conn.assigns, :current_user) do
      %{registration: insert_registration(conn, device)}
    else
      :ok
    end
  end

  defp insert_registration(conn, device) do
    %DeviceRegistration{}
    |> DeviceRegistration.changeset(%{
      title: Faker.App.name(),
      user_id: conn.assigns.current_user.id,
      device_id: device.id
    })
    |> Repo.insert()
    |> elem(1)
  end

  defp build_url(id \\ nil, sub \\ nil) do
    case {id, sub} do
      {nil, _} -> "/v2/devices"
      {id, nil} -> "#{build_url()}/#{id}"
      {id, sub} -> "#{build_url(id)}/#{sub}"
    end
  end
end
