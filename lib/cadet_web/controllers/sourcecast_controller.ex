defmodule CadetWeb.SourcecastController do
  use CadetWeb, :controller
  use PhoenixSwagger

  alias Cadet.Courses

  def index(conn, %{"course_id" => course_id}) do
    sourcecasts = Courses.get_sourcecast_files(course_id)
    render(conn, "index.json", sourcecasts: sourcecasts)
  end

  # def index(conn, _params) do
  #   sourcecasts = Courses.get_sourcecast_files()
  #   render(conn, "index.json", sourcecasts: sourcecasts)
  # end

  # def create(conn, %{"sourcecast" => sourcecast, "public" => _public}) do
  #   result =
  #     Courses.upload_sourcecast_file_public(
  #       conn.assigns.current_user,
  #       conn.assigns.course_reg,
  #       sourcecast
  #     )

  #   case result do
  #     {:ok, _nil} ->
  #       send_resp(conn, 200, "OK")

  #     {:error, {status, message}} ->
  #       conn
  #       |> put_status(status)
  #       |> text(message)
  #   end
  # end

  swagger_path :index do
    get("/courses/{course_id}/sourcecast")
    description("Lists all sourcecasts")
    summary("Show all sourcecasts")
    produces("application/json")
    security([%{JWT: []}])

    response(200, "Success")
    response(400, "Invalid or missing parameter(s)")
    response(401, "Unauthorised")
  end

  def swagger_definitions do
    %{
      Sourcecast:
        swagger_schema do
          properties do
            title(:string, "title", required: true)
            playbackData(:string, "playback data", required: true)
            description(:string, "description", required: false)
            uid(:string, "uid", required: false)

            # Note: this is technically an invalid type in Swagger/OpenAPI 2.0,
            # but represents that a string or integer could be returned.
            audio(:file, "audio file", required: true)
          end
        end
    }
  end
end
