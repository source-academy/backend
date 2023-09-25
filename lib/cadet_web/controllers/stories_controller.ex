defmodule CadetWeb.StoriesController do
  use CadetWeb, :controller
  use PhoenixSwagger

  alias Cadet.Stories.Stories

  def index(conn, %{"course_id" => course_id}) do
    list_all = conn.assigns.course_reg.role in [:admin, :staff]
    stories = Stories.list_stories(course_id, list_all)
    render(conn, "index.json", stories: stories)
  end

  swagger_path :index do
    get("/courses/{course_id}/stories")

    summary("Get a list of all stories")

    security([%{JWT: []}])

    response(200, "OK", Schema.array(:Story))
  end

  @spec swagger_definitions :: %{Story: any}
  def swagger_definitions do
    %{
      Story:
        swagger_schema do
          properties do
            filenames(schema_array(:string), "Filenames of txt files", required: true)
            title(:string, "Title shown in Chapter Select Screen", required: true)
            imageUrl(:string, "Path to image shown in Chapter Select Screen", required: false)
            openAt(:string, "The opening date", format: "date-time", required: true)
            closeAt(:string, "The closing date", format: "date-time", required: true)
            isPublished(:boolean, "Whether or not is published", required: false)
            course_id(:integer, "The id of the course that this story belongs to", required: true)
          end
        end
    }
  end
end
