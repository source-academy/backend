defmodule CadetWeb.AssetsController do
  use CadetWeb, :controller

  use PhoenixSwagger
  alias Cadet.Assets.Assets

  def index(conn, _params = %{"foldername" => foldername}) do
    case Assets.list_assets(foldername, conn.assigns.current_user) do
      {:error, {status, message}} -> conn |> put_status(status) |> text(message)
      assets -> render(conn, "index.json", assets: assets)
    end
  end

  @spec delete(Plug.Conn.t(), map) :: Plug.Conn.t()
  def delete(conn, _params = %{"foldername" => foldername, "filename" => filename}) do
    filename = Enum.join(filename, "/")

    case Assets.delete_object(foldername, filename, conn.assigns.current_user) do
      {:error, {status, message}} -> conn |> put_status(status) |> text(message)
      _ -> conn |> put_status(204) |> text('')
    end
  end

  def upload(conn, %{
        "upload" => upload_params,
        "filename" => filename,
        "foldername" => foldername
      }) do
    filename = Enum.join(filename, "/")

    case Assets.upload_to_s3(upload_params, foldername, filename, conn.assigns.current_user) do
      {:error, {status, message}} -> conn |> put_status(status) |> text(message)
      resp -> render(conn, "show.json", resp: resp)
    end
  end

  def swagger_definitions do
    %{
      Asset:
        swagger_schema do
          title("Asset")
          description("A path to an asset")
          example("assets/hello.png")
        end,
      Assets:
        swagger_schema do
          title("Assets")
          description("An array of asset paths")
          type(:array)
          items(PhoenixSwagger.Schema.ref(:Asset))
        end,
      AssetURL:
        swagger_schema do
          title("Asset URL")
          description("A URL to an uploaded asset")
          type(:string)
          example("https://bucket-name.s3.amazonaws.com/assets/hello.png")
        end
    }
  end

  swagger_path :index do
    get("/assets/{foldername}")

    summary("Get a list of all assets in a folder")

    parameters do
      foldername(:path, :string, "Folder name", required: true)
    end

    security([%{JWT: []}])

    produces("application/json")

    response(200, "OK", :Assets)
    response(400, "Invalid folder name")
    response(403, "User is not allowed to manage assets")
  end

  swagger_path :delete do
    PhoenixSwagger.Path.delete("/assets/{foldername}/{filename}")

    summary("Delete a file from an asset folder")

    parameters do
      foldername(:path, :string, "Folder name", required: true)

      filename(:path, :string, "File path in folder, which may contain subfolders", required: true)
    end

    security([%{JWT: []}])

    produces("application/json")

    response(204, "OK")
    response(400, "Invalid folder name, file name or file type")
    response(403, "User is not allowed to manage assets")
    response(404, "File not found")
  end

  swagger_path :upload do
    post("/assets/{foldername}/{filename}")

    summary("Upload a file to an asset folder")

    parameters do
      foldername(:path, :string, "Folder name", required: true)

      filename(:path, :string, "File path in folder, which may contain subfolders", required: true)
    end

    security([%{JWT: []}])

    produces("application/json")

    response(200, "OK", :AssetURL)
    response(400, "Invalid folder name, file name or file type")
    response(403, "User is not allowed to manage assets")
  end
end
