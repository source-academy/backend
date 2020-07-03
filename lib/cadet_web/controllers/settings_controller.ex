defmodule CadetWeb.SettingsController do
  use CadetWeb, :controller
  use PhoenixSwagger

  alias Cadet.Settings

  def index(conn, _) do
    {:ok, sublanguage} = Settings.get_sublanguage()

    render(conn, "show.json", sublanguage: sublanguage)
  end

  def update(conn, %{"chapter" => chapter, "variant" => variant}) do
    {:ok, sublanguage} = Settings.update_sublanguage(chapter, variant)

    render(conn, "show.json", sublanguage: sublanguage)
  end
end
