defmodule CadetWeb.StoriesController do
  use CadetWeb, :controller
  use PhoenixSwagger

  import Ecto.Query

  alias Cadet.Repo
  alias Cadet.Stories.Story

  def index(conn, _) do
    stories =
      Story
      |> Repo.all()

    render(conn, "index.json", stories: stories)
  end

  def show(conn, params = %{"id" => story_id}) when is_ecto_id(story_id) do

    story =
      Story
      |> where(id: ^story_id)
      |> Repo.one()

    render(conn, "show.json", story: story)
  end

end
