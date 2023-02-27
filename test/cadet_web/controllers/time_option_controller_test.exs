defmodule CadetWeb.TimeOptionControllerTest do
  use CadetWeb.ConnCase

  # import Cadet.NotificationsFixtures

  # alias Cadet.Notifications.TimeOption

  # @create_attrs %{
  #   is_default: true,
  #   minutes: 42
  # }
  # @update_attrs %{
  #   is_default: false,
  #   minutes: 43
  # }
  # @invalid_attrs %{is_default: nil, minutes: nil}

  # setup %{conn: conn} do
  #   {:ok, conn: put_req_header(conn, "accept", "application/json")}
  # end

  # describe "index" do
  #   test "lists all time_options", %{conn: conn} do
  #     conn = get(conn, Routes.time_option_path(conn, :index))
  #     assert json_response(conn, 200)["data"] == []
  #   end
  # end

  # describe "create time_option" do
  #   test "renders time_option when data is valid", %{conn: conn} do
  #     conn = post(conn, Routes.time_option_path(conn, :create), time_option: @create_attrs)
  #     assert %{"id" => id} = json_response(conn, 201)["data"]

  #     conn = get(conn, Routes.time_option_path(conn, :show, id))

  #     assert %{
  #              "id" => ^id,
  #              "is_default" => true,
  #              "minutes" => 42
  #            } = json_response(conn, 200)["data"]
  #   end

  #   test "renders errors when data is invalid", %{conn: conn} do
  #     conn = post(conn, Routes.time_option_path(conn, :create), time_option: @invalid_attrs)
  #     assert json_response(conn, 422)["errors"] != %{}
  #   end
  # end

  # describe "update time_option" do
  #   setup [:create_time_option]

  #   test "renders time_option when data is valid", %{
  #     conn: conn,
  #     time_option: %TimeOption{id: id} = time_option
  #   } do
  #     conn = put(
  #       conn,
  #       Routes.time_option_path(conn, :update, time_option),
  #       time_option: @update_attrs
  #     )
  #     assert %{"id" => ^id} = json_response(conn, 200)["data"]

  #     conn = get(conn, Routes.time_option_path(conn, :show, id))

  #     assert %{
  #              "id" => ^id,
  #              "is_default" => false,
  #              "minutes" => 43
  #            } = json_response(conn, 200)["data"]
  #   end

  #   test "renders errors when data is invalid", %{conn: conn, time_option: time_option} do
  #     conn = put(
  #       conn,
  #       Routes.time_option_path(conn, :update, time_option),
  #       time_option: @invalid_attrs
  #     )
  #     assert json_response(conn, 422)["errors"] != %{}
  #   end
  # end

  # describe "delete time_option" do
  #   setup [:create_time_option]

  #   test "deletes chosen time_option", %{conn: conn, time_option: time_option} do
  #     conn = delete(conn, Routes.time_option_path(conn, :delete, time_option))
  #     assert response(conn, 204)

  #     assert_error_sent 404, fn ->
  #       get(conn, Routes.time_option_path(conn, :show, time_option))
  #     end
  #   end
  # end

  # defp create_time_option(_) do
  #   time_option = time_option_fixture()
  #   %{time_option: time_option}
  # end
end
