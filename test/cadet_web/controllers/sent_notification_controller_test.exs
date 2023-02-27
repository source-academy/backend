defmodule CadetWeb.SentNotificationControllerTest do
  use CadetWeb.ConnCase

  # import Cadet.NotificationsFixtures

  # alias Cadet.Notifications.SentNotification

  # @create_attrs %{
  #   content: "some content"
  # }
  # @update_attrs %{
  #   content: "some updated content"
  # }
  # @invalid_attrs %{content: nil}

  # setup %{conn: conn} do
  #   {:ok, conn: put_req_header(conn, "accept", "application/json")}
  # end

  # describe "index" do
  #   test "lists all sent_notifications", %{conn: conn} do
  #     conn = get(conn, Routes.sent_notification_path(conn, :index))
  #     assert json_response(conn, 200)["data"] == []
  #   end
  # end

  # describe "create sent_notification" do
  #   test "renders sent_notification when data is valid", %{conn: conn} do
  #     conn = post(
  #       conn,
  #       Routes.sent_notification_path(conn, :create),
  #       sent_notification: @create_attrs
  #     )
  #     assert %{"id" => id} = json_response(conn, 201)["data"]

  #     conn = get(conn, Routes.sent_notification_path(conn, :show, id))

  #     assert %{
  #              "id" => ^id,
  #              "content" => "some content"
  #            } = json_response(conn, 200)["data"]
  #   end

  #   test "renders errors when data is invalid", %{conn: conn} do
  #     conn = post(
  #       conn,
  #       Routes.sent_notification_path(conn, :create),
  #       sent_notification: @invalid_attrs
  #     )
  #     assert json_response(conn, 422)["errors"] != %{}
  #   end
  # end

  # describe "update sent_notification" do
  #   setup [:create_sent_notification]

    # test "renders sent_notification when data is valid", %{
    #   conn: conn,
    #   sent_notification: %SentNotification{id: id} = sent_notification
    # } do
    #   conn = put(
    #     conn,
    #     Routes.sent_notification_path(conn, :update, sent_notification),
    #     sent_notification: @update_attrs
    #   )
    #   assert %{"id" => ^id} = json_response(conn, 200)["data"]

    #   conn = get(conn, Routes.sent_notification_path(conn, :show, id))

    #   assert %{
    #            "id" => ^id,
    #            "content" => "some updated content"
    #          } = json_response(conn, 200)["data"]
    # end

  #   test "renders errors when data is invalid", %{
  #     conn: conn,
  #     sent_notification: sent_notification
  #   } do
  #     conn = put(
  #       conn,
  #       Routes.sent_notification_path(conn, :update, sent_notification),
  #       sent_notification: @invalid_attrs
  #     )
  #     assert json_response(conn, 422)["errors"] != %{}
  #   end
  # end

  # describe "delete sent_notification" do
  #   setup [:create_sent_notification]

  #   test "deletes chosen sent_notification", %{conn: conn, sent_notification: sent_notification} do
  #     conn = delete(conn, Routes.sent_notification_path(conn, :delete, sent_notification))
  #     assert response(conn, 204)

  #     assert_error_sent 404, fn ->
  #       get(conn, Routes.sent_notification_path(conn, :show, sent_notification))
  #     end
  #   end
  # end

  # defp create_sent_notification(_) do
  #   sent_notification = sent_notification_fixture()
  #   %{sent_notification: sent_notification}
  # end
end
