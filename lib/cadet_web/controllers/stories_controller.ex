defmodule CadetWeb.StoriesController do
  use CadetWeb, :controller
  use PhoenixSwagger

  alias Cadet.Stories.Stories

  def index(conn, _) do
    stories = Stories.list_stories(conn.assigns.current_user)
    render(conn, "index.json", stories: stories)
  end

  def create(conn, story) do
    result =
      story
      |> snake_casify_string_keys()
      |> Stories.create_story(conn.assigns.current_user)

    case result do
      {:ok, _story} ->
        conn |> put_status(200) |> text('')

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end

  def update(conn, _params = %{"storyid" => id, "story" => story}) do
    result =
      story
      |> snake_casify_string_keys()
      |> Stories.update_story(id, conn.assigns.current_user)

    case result do
      {:ok, _story} ->
        conn |> put_status(200) |> text('')

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end

  def delete(conn, _params = %{"storyid" => id}) do
    result = Stories.delete_story(id, conn.assigns.current_user)

    case result do
      {:ok, _nil} ->
        conn |> put_status(204) |> text('')

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end

  swagger_path :index do
    get("/stories")

    summary("Get a list of all stories")

    security([%{JWT: []}])

    response(200, "OK", :Stories)
    response(403, "User not allowed to manage stories")
  end

  swagger_path :create do
    post("/stories")

    summary("Creates a new story")

    security([%{JWT: []}])

    response(200, "OK", :Story)
    response(400, "Bad request")
    response(403, "User not allowed to manage stories")
  end

  swagger_path :delete do
    PhoenixSwagger.Path.delete("/stories/{storyid}")

    summary("Delete a story from database by id")

    parameters do
      storyid(:path, :integer, "Story Id", required: true)
    end

    security([%{JWT: []}])

    response(204, "OK")
    response(403, "User not allowed to manage stories")
    response(404, "Story not found")
  end

  swagger_path :update do
    post("/stories/{storyid}")

    summary("Update details regarding a story")

    parameters do
      storyid(:path, :integer, "Story Id", required: true)
    end

    security([%{JWT: []}])

    produces("application/json")

    response(200, "OK", :Story)
    response(403, "User not allowed to manage stories")
    response(404, "Story not found")
  end

  @spec swagger_definitions :: %{Story: any}
  def swagger_definitions do
    %{
      Story:
        swagger_schema do
          properties do
            filenames(:string, "Filenames of txt files", required: true)
            title(:string, "Title shown in Chapter Select Screen", required: true)
            imageUrl(:string, "Path to image shown in Chapter Select Screen", required: false)
            openAt(:string, "The opening date", format: "date-time", required: true)
            closeAt(:string, "The closing date", format: "date-time", required: true)
            isPublished(:boolean, "Whether or not is published", required: false)
          end
        end
    }
  end
end
