defmodule CadetWeb.AssetsController do
  use CadetWeb, :controller

  use PhoenixSwagger
  alias Cadet.Assets.Assets

  def index(conn, _params = %{"foldername" => foldername}) do
    with :ok <- Assets.validate_assets_role(conn),
         :ok <- Assets.validate_folder_name(foldername) do
      assets = Assets.list_assets(foldername)
      render(conn, "index.json", assets: assets)
    else
      {:error, {status, message}} -> conn |> put_status(status) |> text(message)
    end
  end

  @spec delete(Plug.Conn.t(), map) :: Plug.Conn.t()
  def delete(conn, _params = %{"foldername" => foldername, "filename" => filename}) do
    filename = Enum.join(filename, "/")

    with :ok <- Assets.validate_assets_role(conn),
         :ok <- Assets.filename_not_empty(filename),
         :ok <- Assets.validate_folder_name(foldername) do
      Assets.delete_object(foldername, filename)
      conn |> put_status(204) |> text('')
    else
      {:error, {status, message}} -> conn |> put_status(status) |> text(message)
    end
  end

  def upload(conn, %{
        "upload" => upload_params,
        "filename" => filename,
        "foldername" => foldername
      }) do
    filename = Enum.join(filename, "/")
    filetype = Path.extname(filename)

    with :ok <- Assets.validate_assets_role(conn),
         :ok <- Assets.filename_not_empty(filename),
         :ok <- Assets.validate_folder_name(foldername),
         :ok <- Assets.validate_filetype(filetype) do
      resp = Assets.upload_to_s3(upload_params, foldername, filename)
      render(conn, "show.json", resp: resp)
    else
      {:error, {status, message}} -> conn |> put_status(status) |> text(message)
    end
  end

  swagger_path :index do
    get("/assets/:foldername")

    summary("Get a list of all assets in a foldername")

    security([%{JWT: []}])

    produces("application/json")

    response(200, "OK")
    response(400, "Bad Request")
    response(401, "Unauthorised")
  end

  swagger_path :delete do
    post("assets/:foldername/*filename")

    summary("Delete a file from an asset folder")

    security([%{JWT: []}])

    produces("application/json")

    response(200, "OK")
    response(400, "Bad Request")
    response(401, "Unauthorised")
  end

  swagger_path :upload do
    post("/assets/:foldername/*filename")

    summary("Upload a file to an asset folder")

    security([%{JWT: []}])

    produces("application/json")

    response(200, "OK")
    response(400, "Bad Request")
    response(401, "Unauthorised")
  end
end
