defmodule CadetWeb.AdminSourcecastController do
  use CadetWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias Cadet.Courses
  alias CadetWeb.ApiSpec.ErrorResponses
  alias CadetWeb.Schemas

  tags(["Sourcecast"])
  security([%{"JWT" => []}])

  operation(:create,
    summary: "Upload a sourcecast",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"]
    ],
    request_body:
      {"The sourcecast to upload", "multipart/form-data", Schemas.CreateSourcecastRequest},
    responses: [
      ok: {"Sourcecast uploaded", "text/plain", %OpenApiSpex.Schema{type: :string}},
      bad_request: ErrorResponses.bad_request(),
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden()
    ]
  )

  def create(conn, %{"sourcecast" => sourcecast}) do
    result = Courses.upload_sourcecast_file(conn.assigns.course_reg, sourcecast)

    case result do
      {:ok, _nil} ->
        send_resp(conn, 200, "OK")

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end

  def create(conn, _params) do
    send_resp(conn, :bad_request, "Missing or invalid parameter(s)")
  end

  operation(:delete,
    summary: "Delete a sourcecast",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"],
      id: [in: :path, type: :integer, required: true, description: "Sourcecast ID"]
    ],
    responses: [
      ok: {"Sourcecast deleted", "text/plain", %OpenApiSpex.Schema{type: :string}},
      bad_request: ErrorResponses.bad_request(),
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden()
    ]
  )

  def delete(conn, %{"id" => id}) do
    result = Courses.delete_sourcecast_file(id)

    case result do
      {:ok, _nil} ->
        send_resp(conn, 200, "OK")

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end
end
