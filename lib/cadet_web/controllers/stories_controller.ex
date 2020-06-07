defmodule CadetWeb.StoriesController do
  use CadetWeb, :controller
  use PhoenixSwagger

  import Ecto.Query

  alias Cadet.Repo
  alias Cadet.Stories.Story

  @view_stories_role ~w(staff admin)a

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

  def create(conn, params= )


  swagger_path :index do
    get("/stories")

    summary("Get a list of all stories")

    security([%{JWT: []}])

    response(200, "OK")
    response(400, "Invalid parameters")
    response(404, "Submission not found")
  end

  def swagger_definitions do
    %{
      Story:
        swagger_schema do
          properties do
            filename(:string, "The filename", required: true)
            openAt(:string, "The opening date", format: "date-time", required: true)
            closeAt(:string, "The closing date", format: "date-time", required: true)
            isPublished(:boolean, "Whether or not is published", required: true)
          end
        end
    }
  end


end
