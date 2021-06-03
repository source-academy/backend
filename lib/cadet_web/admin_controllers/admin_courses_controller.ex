defmodule CadetWeb.AdminCoursesController do
  use CadetWeb, :controller

  use PhoenixSwagger

  alias Cadet.Courses

  def update_sublanguage(conn, %{
        "courseid" => course_id,
        "chapter" => chapter,
        "variant" => variant
      })
      when is_ecto_id(course_id) do
    case Courses.update_sublanguage(course_id, chapter, variant) do
      {:ok, _} ->
        text(conn, "OK")

      {:error, {status, message}} ->
        send_resp(conn, status, message)

      {:error, _} ->
        conn
        |> put_status(:bad_request)
        |> text("Invalid parameter(s)")
    end
  end

  def update_sublanguage(conn, _) do
    send_resp(conn, :bad_request, "Missing parameter(s)")
  end

  swagger_path :update do
    put("/admin/courses/{courseId}/sublanguage")

    summary("Updates the default Source sublanguage of the Playground for the specified course")

    security([%{JWT: []}])

    consumes("application/json")

    parameters do
      courseId(:path, :integer, "Course ID", required: true)
      sublanguage(:body, Schema.ref(:AdminSublanguage), "sublanguage object", required: true)
    end

    response(200, "OK")
    response(400, "Missing or invalid parameter(s)")
    response(403, "Forbidden")
  end

  def swagger_definitions do
    %{
      AdminSublanguage:
        swagger_schema do
          title("AdminSublanguage")

          properties do
            chapter(:integer, "Chapter number from 1 to 4", required: true, minimum: 1, maximum: 4)

            variant(Schema.ref(:SourceVariant), "Variant name", required: true)
          end

          example(%{
            chapter: 2,
            variant: "lazy"
          })
        end
    }
  end
end
