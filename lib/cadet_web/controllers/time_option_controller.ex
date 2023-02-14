defmodule CadetWeb.TimeOptionController do
  use CadetWeb, :controller

  alias Cadet.Notifications
  alias Cadet.Notifications.TimeOption

  # action_fallback CadetWeb.FallbackController

  def index(conn, _params) do
    time_options = Notifications.list_time_options()
    render(conn, "index.json", time_options: time_options)
  end

  def create(conn, %{"time_option" => time_option_params}) do
    with {:ok, %TimeOption{} = time_option} <-
           Notifications.create_time_option(time_option_params) do
      conn
      |> put_status(:created)
      # |> put_resp_header("location", Routes.time_option_path(conn, :show, time_option))
      |> render("show.json", time_option: time_option)
    end
  end

  def show(conn, %{"id" => id}) do
    time_option = Notifications.get_time_option!(id)
    render(conn, "show.json", time_option: time_option)
  end

  def update(conn, %{"id" => id, "time_option" => time_option_params}) do
    time_option = Notifications.get_time_option!(id)

    with {:ok, %TimeOption{} = time_option} <-
           Notifications.update_time_option(time_option, time_option_params) do
      render(conn, "show.json", time_option: time_option)
    end
  end

  def delete(conn, %{"id" => id}) do
    time_option = Notifications.get_time_option!(id)

    with {:ok, %TimeOption{}} <- Notifications.delete_time_option(time_option) do
      send_resp(conn, :no_content, "")
    end
  end
end
