defmodule CadetWeb.SourcecastController do
  use CadetWeb, :controller
  use PhoenixSwagger

  alias Cadet.{Repo, Course}
  alias Cadet.Course.{Sourcecast}

  def index(conn, _params) do
    sourcecasts = Sourcecast |> Repo.all() |> Repo.preload(:uploader)
    render(conn, "index.json", sourcecasts: sourcecasts)
  end

  def create(conn, %{"sourcecast" => sourcecast}) do
    IO.inspect(sourcecast)
    result = Course.upload_sourcecast_file(conn.assigns.current_user, sourcecast)
    IO.inspect(result)

    case result do
      {:ok, _nil} ->
        send_resp(conn, 200, "")

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end

  def delete(conn, %{"id" => id}) do
    result = Course.delete_material(id)

    case result do
      {:ok, _nil} ->
        send_resp(conn, 200, "")

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end

  swagger_path :index do
    get("/sourcecast")
    description("Lists all sourcecast files")
    produces("application/json")
    summary("Shows all files")
    security([%{JWT: []}])

    response(200, "Success")
    response(400, "Invalid or missing parameter(s)")
    response(401, "Unauthorised")
  end

  swagger_path :create do
    post("/sourcecast")
    description("Uploads file")
    summary("Upload file")
    consumes("multipart/form-data")
    security([%{JWT: []}])

    parameters do
      sourcecast(:body, Schema.ref(:Sourcecast), "sourcecast object", required: true)
    end

    response(200, "Success")
    response(400, "Invalid or missing parameter(s)")
    response(401, "Unauthorised")
  end

  swagger_path :delete do
    PhoenixSwagger.Path.delete("/sourcecast/{id}")
    description("Deletes file by specifying the file id")
    summary("Delete file")
    security([%{JWT: []}])

    parameters do
      id(:path, :integer, "file id", required: true)
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
            name(:string, "name", required: true)
            audio(:file, "audio file", required: true)
            deltas(:string, "playback deltas", required: true)
          end
        end
    }
  end
end
