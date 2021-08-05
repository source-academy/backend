defmodule CadetWeb.AdminSourcecastController do
  use CadetWeb, :controller
  use PhoenixSwagger

  alias Cadet.Courses

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

  swagger_path :create do
    post("/sourcecast")
    description("Uploads sourcecast")
    summary("Upload sourcecast")
    consumes("multipart/form-data")
    security([%{JWT: []}])

    parameters do
      public(
        :body,
        :boolean,
        "Uploads as public sourcecast when 'public' is specified regardless of truthy or falsy"
      )

      sourcecast(:body, Schema.ref(:Sourcecast), "sourcecast object", required: true)
    end

    response(200, "Success")
    response(400, "Invalid or missing parameter(s)")
    response(401, "Unauthorised")
  end

  swagger_path :delete do
    PhoenixSwagger.Path.delete("/sourcecast/{id}")
    description("Deletes sourcecast by id")
    summary("Delete sourcecast")
    security([%{JWT: []}])

    parameters do
      id(:path, :integer, "sourcecast id", required: true)
    end

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
