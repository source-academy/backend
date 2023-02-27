defmodule CadetWeb.NotificationTypeControllerTest do
  use CadetWeb.ConnCase

  # import Cadet.NotificationsFixtures

  # alias Cadet.Notifications.NotificationType

  # @create_attrs %{
  #   is_autopopulated: true,
  #   is_enabled: true,
  #   name: "some name",
  #   template_file_name: "some template_file_name"
  # }
  # @update_attrs %{
  #   is_autopopulated: false,
  #   is_enabled: false,
  #   name: "some updated name",
  #   template_file_name: "some updated template_file_name"
  # }
  # @invalid_attrs %{is_autopopulated: nil, is_enabled: nil, name: nil, template_file_name: nil}

  # setup %{conn: conn} do
  #   {:ok, conn: put_req_header(conn, "accept", "application/json")}
  # end

  # describe "index" do
  #   test "lists all notification_types", %{conn: conn} do
  #     conn = get(conn, Routes.notification_type_path(conn, :index))
  #     assert json_response(conn, 200)["data"] == []
  #   end
  # end

  # describe "create notification_type" do
  #   test "renders notification_type when data is valid", %{conn: conn} do
  #     conn = post(
  #       conn,
  #       Routes.notification_type_path(conn, :create),
  #       notification_type: @create_attrs
  #     )
  #     assert %{"id" => id} = json_response(conn, 201)["data"]

  #     conn = get(conn, Routes.notification_type_path(conn, :show, id))

  #     assert %{
  #              "id" => ^id,
  #              "is_autopopulated" => true,
  #              "is_enabled" => true,
  #              "name" => "some name",
  #              "template_file_name" => "some template_file_name"
  #            } = json_response(conn, 200)["data"]
  #   end

  #   test "renders errors when data is invalid", %{conn: conn} do
  #     conn = post(
  #       conn,
  #       Routes.notification_type_path(conn, :create),
  #       notification_type: @invalid_attrs
  #     )
  #     assert json_response(conn, 422)["errors"] != %{}
  #   end
  # end

  # describe "update notification_type" do
  #   setup [:create_notification_type]

    # test "renders notification_type when data is valid", %{
    #   conn: conn,
    #   notification_type: %NotificationType{id: id} = notification_type
    # } do
    #   conn = put(
    #     conn,
    #     Routes.notification_type_path(conn, :update, notification_type),
    #     notification_type: @update_attrs
    #   )
    #   assert %{"id" => ^id} = json_response(conn, 200)["data"]

    #   conn = get(conn, Routes.notification_type_path(conn, :show, id))

    #   assert %{
    #            "id" => ^id,
    #            "is_autopopulated" => false,
    #            "is_enabled" => false,
    #            "name" => "some updated name",
    #            "template_file_name" => "some updated template_file_name"
    #          } = json_response(conn, 200)["data"]
    # end

  #   test "renders errors when data is invalid", %{
  #     conn: conn,
  #     notification_type: notification_type
  #   } do
  #     conn = put(
  #       conn,
  #       Routes.notification_type_path(conn, :update, notification_type),
  #       notification_type: @invalid_attrs
  #     )
  #     assert json_response(conn, 422)["errors"] != %{}
  #   end
  # end

  # describe "delete notification_type" do
  #   setup [:create_notification_type]

  #   test "deletes chosen notification_type", %{
  #     conn: conn,
  #     notification_type: notification_type
  #   } do
  #     conn = delete(conn, Routes.notification_type_path(conn, :delete, notification_type))
  #     assert response(conn, 204)

  #     assert_error_sent 404, fn ->
  #       get(conn, Routes.notification_type_path(conn, :show, notification_type))
  #     end
  #   end
  # end

  # defp create_notification_type(_) do
  #   notification_type = notification_type_fixture()
  #   %{notification_type: notification_type}
  # end
end
