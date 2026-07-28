defmodule CadetWeb.SourcecastController do
  use CadetWeb, :controller
  use OpenApiSpex.ControllerSpecs

  plug(OpenApiSpex.Plug.CastAndValidate,
    render_error: CadetWeb.Plugs.OpenApiErrorRenderer,
    replace_params: false
  )

  alias Cadet.Courses
  alias CadetWeb.ApiSpec.ErrorResponses
  alias CadetWeb.Schemas
  alias OpenApiSpex.Schema

  tags(["Sourcecast"])
  security([%{"JWT" => []}])

  operation(:index,
    summary: "Get all sourcecasts in the course",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"]
    ],
    responses: [
      ok:
        {"List of sourcecasts", "application/json",
         %Schema{type: :array, items: Schemas.Sourcecast}},
      bad_request: ErrorResponses.bad_request(),
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden()
    ]
  )

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
end
