defmodule CadetWeb.CoursesController do
  use CadetWeb, :controller

  use PhoenixSwagger

  alias Cadet.Courses

  def get_sublanguage(conn, %{"courseid" => course_id}) when is_ecto_id(course_id) do
    case Courses.get_sublanguage(course_id) do
      {:ok, sublanguage} -> render(conn, "sublanguage.json", sublanguage: sublanguage)
      {:error, {status, message}} -> send_resp(conn, status, message)
    end
  end

  swagger_path :get_sublanguage do
    get("/courses/{courseId}/sublanguage")

    summary("Retrieves the default Source sublanguage of the Playground for the specified course")

    security([%{JWT: []}])

    produces("application/json")

    parameters do
      courseId(:path, :integer, "Course ID", required: true)
    end

    response(200, "OK", Schema.ref(:Sublanguage))
    response(400, "Invalid courseId")
  end

  def swagger_definitions do
    %{
      Sublanguage:
        swagger_schema do
          title("Sublanguage")

          properties do
            chapter(:integer, "Chapter number from 1 to 4", required: true, minimum: 1, maximum: 4)

            variant(Schema.ref(:SourceVariant), "Variant name", required: true)
          end

          example(%{
            chapter: 1,
            variant: "default"
          })
        end,
      SourceVariant:
        swagger_schema do
          type(:string)
          enum([:default, :concurrent, :gpu, :lazy, "non-det", :wasm])
        end
    }
  end
end
