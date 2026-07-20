defmodule CadetWeb.StoriesController do
  use CadetWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias Cadet.Stories.Stories
  alias CadetWeb.ApiSpec.ErrorResponses
  alias CadetWeb.Schemas
  alias OpenApiSpex.Schema

  tags(["Stories"])
  security([%{"JWT" => []}])

  operation(:index,
    summary: "Get all stories in the course",
    description:
      "Students receive only published, open stories; staff and admins receive all stories.",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"]
    ],
    responses: [
      ok: {"List of stories", "application/json", %Schema{type: :array, items: Schemas.Story}},
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden()
    ]
  )

  def index(conn, %{"course_id" => course_id}) do
    list_all = conn.assigns.course_reg.role in [:admin, :staff]
    stories = Stories.list_stories(course_id, list_all)
    render(conn, "index.json", stories: stories)
  end
end
