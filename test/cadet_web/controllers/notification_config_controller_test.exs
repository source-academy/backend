defmodule CadetWeb.NotificationConfigControllerTest do
  use CadetWeb.ConnCase

  # import Cadet.NotificationsFixtures

  # alias Cadet.Notifications.NotificationConfig

  # @create_attrs %{
  #   is_enabled: true
  # }
  # @update_attrs %{
  #   is_enabled: false
  # }
  # @invalid_attrs %{is_enabled: nil}

  # setup %{conn: conn} do
  #   {:ok, conn: put_req_header(conn, "accept", "application/json")}
  # end

  # describe "index" do
  #   test "lists all notification_configs", %{conn: conn} do
  #     conn = get(conn, Routes.notification_config_path(conn, :index))
  #     assert json_response(conn, 200)["data"] == []
  #   end
  # end

  # describe "create notification_config" do
  #   test "renders notification_config when data is valid", %{conn: conn} do
  #     conn = post(
  #       conn,
  #       Routes.notification_config_path(conn, :create),
  #       notification_config: @create_attrs
  #     )
  #     assert %{"id" => id} = json_response(conn, 201)["data"]

  #     conn = get(conn, Routes.notification_config_path(conn, :show, id))

  #     assert %{
  #              "id" => ^id,
  #              "is_enabled" => true
  #            } = json_response(conn, 200)["data"]
  #   end

  #   test "renders errors when data is invalid", %{conn: conn} do
  #     conn = post(
  #       conn,
  #       Routes.notification_config_path(conn, :create),
  #       notification_config: @invalid_attrs
  #     )
  #     assert json_response(conn, 422)["errors"] != %{}
  #   end
  # end

  # describe "update notification_config" do
  #   setup [:create_notification_config]

  #   test "renders notification_config when data is valid", %{
  #     conn: conn,
  #     notification_config: %NotificationConfig{id: id} = notification_config
  #   } do
  #     conn = put(
  #       conn,
  #       Routes.notification_config_path(conn, :update, notification_config),
  #       notification_config: @update_attrs
  #     )
  #     assert %{"id" => ^id} = json_response(conn, 200)["data"]

  #     conn = get(conn, Routes.notification_config_path(conn, :show, id))

  #     assert %{
  #              "id" => ^id,
  #              "is_enabled" => false
  #            } = json_response(conn, 200)["data"]
  #   end

  #   test "renders errors when data is invalid", %{conn: conn, notification_config: notification_config} do
  #     conn = put(
  #       conn,
  #       Routes.notification_config_path(conn, :update, notification_config),
  #       notification_config: @invalid_attrs
  #     )
  #     assert json_response(conn, 422)["errors"] != %{}
  #   end
  # end

  # describe "delete notification_config" do
  #   setup [:create_notification_config]

  #   test "deletes chosen notification_config", %{conn: conn, notification_config: notification_config} do
  #     conn = delete(conn, Routes.notification_config_path(conn, :delete, notification_config))
  #     assert response(conn, 204)

  #     assert_error_sent 404, fn ->
  #       get(conn, Routes.notification_config_path(conn, :show, notification_config))
  #     end
  #   end
  # end

  # defp create_notification_config(_) do
  #   notification_config = notification_config_fixture()
  #   %{notification_config: notification_config}
  # end
end
