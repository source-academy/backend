defmodule CadetWeb.SettingsController do
  use CadetWeb, :controller
  use PhoenixSwagger

  alias Cadet.Settings

  @set_sublanguage_roles ~w(staff admin)a

  def index(conn, _) do
    {:ok, sublanguage} = Settings.get_sublanguage()

    render(conn, "show.json", sublanguage: sublanguage)
  end

  def update(conn, %{"chapter" => chapter, "variant" => variant}) do
    role = conn.assigns[:current_user].role

    if role in @set_sublanguage_roles do
      case Settings.update_sublanguage(chapter, variant) do
        {:ok, _} ->
          text(conn, "OK")

        {:error, _} ->
          conn
          |> put_status(:bad_request)
          |> text("Invalid parameter(s)")
      end
    else
      conn
      |> put_status(:forbidden)
      |> text("User not allowed to set default Playground sublanguage.")
    end
  end

  def logout(conn, _) do
    send_resp(conn, :bad_request, "Missing parameter(s)")
  end
end
