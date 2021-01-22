defmodule CadetWeb.ControllerHelperTest do
  use ExUnit.Case
  import Mock

  alias Plug.Conn
  import CadetWeb.ControllerHelper

  describe "handle_standard_result" do
    test_with_mock "sends 204 with {:ok}", Conn, send_resp: fn _, _, _ -> nil end do
      handle_standard_result({:ok, nil}, :conn)
      assert_called(Conn.send_resp(:conn, :no_content, ""))
    end

    test_with_mock "sends 204 with :ok", Conn, send_resp: fn _, _, _ -> nil end do
      handle_standard_result(:ok, :conn)
      assert_called(Conn.send_resp(:conn, :no_content, ""))
    end

    test_with_mock "sends 204 with {:ok} and empty string", Conn, send_resp: fn _, _, _ -> nil end do
      handle_standard_result({:ok, nil}, :conn, "")
      assert_called(Conn.send_resp(:conn, :no_content, ""))
    end

    test_with_mock "sends 204 with :ok and empty string", Conn, send_resp: fn _, _, _ -> nil end do
      handle_standard_result(:ok, :conn, "")
      assert_called(Conn.send_resp(:conn, :no_content, ""))
    end

    test_with_mock "sends 200 with {:ok} and body", Conn, send_resp: fn _, _, _ -> nil end do
      handle_standard_result({:ok, nil}, :conn, "OK")
      assert_called(Conn.send_resp(:conn, :ok, "OK"))
    end

    test_with_mock "sends 200 with :ok and body", Conn, send_resp: fn _, _, _ -> nil end do
      handle_standard_result(:ok, :conn, "OK")
      assert_called(Conn.send_resp(:conn, :ok, "OK"))
    end

    test_with_mock "sends error", Conn, send_resp: fn _, _, _ -> nil end do
      handle_standard_result({:error, {:not_found, "Not found"}}, :conn)
      assert_called(Conn.send_resp(:conn, :not_found, "Not found"))
    end
  end
end
