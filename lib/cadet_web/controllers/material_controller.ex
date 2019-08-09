defmodule CadetWeb.MaterialController do
  use CadetWeb, :controller
  use PhoenixSwagger

  alias Cadet.{Repo, Course}
  alias Cadet.Course.{Category, Material}

  def index(conn, %{"id" => id}) do
    render(conn, "index.json", materials: Course.list_material_folders(id))
  end

  def index(conn, _params) do
    render(conn, "index.json", materials: Course.list_material_folders(nil))
  end

  def create(conn, %{"material" => material}) do
    IO.inspect(material)
    result = Course.upload_material_file(conn.assigns.current_user, material)
    IO.inspect(result)

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
    result = Course.delete_material(conn.assigns.current_user, id)

    case result do
      {:ok, _nil} ->
        send_resp(conn, 200, "OK")

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end

  swagger_path :index do
    get("/material")
    description("Lists all material files")
    produces("application/json")
    summary("Shows all files")
    security([%{JWT: []}])

    response(200, "Success")
    response(400, "Invalid or missing parameter(s)")
    response(401, "Unauthorised")
  end

  swagger_path :create do
    post("/material")
    description("Uploads file")
    summary("Upload file")
    consumes("multipart/form-data")
    security([%{JWT: []}])

    parameters do
      material(:body, Schema.ref(:Material), "material object", required: true)
    end

    response(200, "Success")
    response(400, "Invalid or missing parameter(s)")
    response(401, "Unauthorised")
  end

  swagger_path :delete do
    PhoenixSwagger.Path.delete("/material/{id}")
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
      Material:
        swagger_schema do
          properties do
            name(:string, "name", required: true)
            file(:file, "binary file", required: true)
          end
        end
    }
  end
end
