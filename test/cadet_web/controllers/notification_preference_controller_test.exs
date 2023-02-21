defmodule CadetWeb.NotificationPreferenceControllerTest do
  use CadetWeb.ConnCase

  # import Cadet.NotificationsFixtures

  # alias Cadet.Notifications.NotificationPreference

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
  #   test "lists all notification_preferences", %{conn: conn} do
  #     conn = get(conn, Routes.notification_preference_path(conn, :index))
  #     assert json_response(conn, 200)["data"] == []
  #   end
  # end

  # describe "create notification_preference" do
  #   test "renders notification_preference when data is valid", %{conn: conn} do
  #     conn = post(conn, Routes.notification_preference_path(conn, :create), notification_preference: @create_attrs)
  #     assert %{"id" => id} = json_response(conn, 201)["data"]

  #     conn = get(conn, Routes.notification_preference_path(conn, :show, id))

  #     assert %{
  #              "id" => ^id,
  #              "is_enabled" => true
  #            } = json_response(conn, 200)["data"]
  #   end

  #   test "renders errors when data is invalid", %{conn: conn} do
  #     conn = post(conn, Routes.notification_preference_path(conn, :create), notification_preference: @invalid_attrs)
  #     assert json_response(conn, 422)["errors"] != %{}
  #   end
  # end

  # describe "update notification_preference" do
  #   setup [:create_notification_preference]

  #   test "renders notification_preference when data is valid", %{conn: conn, notification_preference: %NotificationPreference{id: id} = notification_preference} do
  #     conn = put(conn, Routes.notification_preference_path(conn, :update, notification_preference), notification_preference: @update_attrs)
  #     assert %{"id" => ^id} = json_response(conn, 200)["data"]

  #     conn = get(conn, Routes.notification_preference_path(conn, :show, id))

  #     assert %{
  #              "id" => ^id,
  #              "is_enabled" => false
  #            } = json_response(conn, 200)["data"]
  #   end

  #   test "renders errors when data is invalid", %{conn: conn, notification_preference: notification_preference} do
  #     conn = put(conn, Routes.notification_preference_path(conn, :update, notification_preference), notification_preference: @invalid_attrs)
  #     assert json_response(conn, 422)["errors"] != %{}
  #   end
  # end

  # describe "delete notification_preference" do
  #   setup [:create_notification_preference]

  #   test "deletes chosen notification_preference", %{conn: conn, notification_preference: notification_preference} do
  #     conn = delete(conn, Routes.notification_preference_path(conn, :delete, notification_preference))
  #     assert response(conn, 204)

  #     assert_error_sent 404, fn ->
  #       get(conn, Routes.notification_preference_path(conn, :show, notification_preference))
  #     end
  #   end
  # end

  # defp create_notification_preference(_) do
  #   notification_preference = notification_preference_fixture()
  #   %{notification_preference: notification_preference}
  # end
end
