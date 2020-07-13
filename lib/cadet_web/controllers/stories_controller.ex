defmodule CadetWeb.StoriesController do
  use CadetWeb, :controller
  use PhoenixSwagger

  alias Cadet.Repo
  alias Cadet.Stories.Story
  alias Cadet.Stories.Stories

  def index(conn, _) do
    stories =
      Story
      |> Repo.all()

    render(conn, "index.json", stories: stories)
  end

  def create(conn, %{"story" => story}) do
    result = Stories.create_story(conn.assigns.current_user, story)

    case result do
      {:ok, _nil} ->
        send_resp(conn, 200, "OK")

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end

  def update(conn, %{"story" => story}, id) do
    result = Stories.update_story(conn.assigns.current_user, story, id)

    case result do
      {:ok, _nil} ->
        text(conn, "OK")

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end

  def delete(conn, _) do
    stories =
      Story
      |> Repo.all()

    render(conn, "index.json", stories: stories)
  end

  swagger_path :index do
    get("/stories")

    summary("Get a list of all stories")

    security([%{JWT: []}])

    response(200, "OK", :Stories)
    response(400, "Bad request")
  end

  @spec swagger_definitions :: %{Story: any}
  def swagger_definitions do
    %{
      Story:
        swagger_schema do
          properties do
            filenames(:string, "Filenames of txt files", required: true)
            title(:string, "Title shown in Chapter Select Screen", required: true)
            title(:string, "Title shown in Chapter Select Screen", required: true)
            openAt(:string, "The opening date", format: "date-time", required: true)
            closeAt(:string, "The closing date", format: "date-time", required: true)
            isPublished(:boolean, "Whether or not is published", required: true)
          end
        end
    }
  end
end
