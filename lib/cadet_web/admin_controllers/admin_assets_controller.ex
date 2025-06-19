defmodule CadetWeb.AdminAssetsController do
  use CadetWeb, :controller

  use PhoenixSwagger

  alias Cadet.Assets.Assets
  alias Cadet.Courses

  def index(conn, _params = %{"foldername" => foldername}) do
    course_reg = conn.assigns.course_reg

    case Assets.list_assets(Courses.assets_prefix(course_reg.course), foldername) do
      {:error, {status, message}} -> conn |> put_status(status) |> text(message)
      assets -> render(conn, "index.json", assets: assets)
    end
  end

  @spec delete(Plug.Conn.t(), map) :: Plug.Conn.t()
  def delete(conn, _params = %{"foldername" => foldername, "filename" => filename}) do
    course_reg = conn.assigns.course_reg
    filename = Enum.join(filename, "/")

    case Assets.delete_object(Courses.assets_prefix(course_reg.course), foldername, filename) do
      {:error, {status, message}} -> conn |> put_status(status) |> text(message)
      _ -> conn |> put_status(204) |> text("")
    end
  end

  # Ignore the dialyzer warning, just ctrl click the
  # `Assets.upload_to_s3` function to see the type,
  # it clearly returns a string URL
  @dialyzer {:no_match, upload: 2}

  def upload(conn, %{
        "upload" => upload_params,
        "filename" => filename,
        "foldername" => foldername
      }) do
    course_reg = conn.assigns.course_reg
    filename = Enum.join(filename, "/")

    case Assets.upload_to_s3(
           upload_params,
           Courses.assets_prefix(course_reg.course),
           foldername,
           filename
         ) do
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
    get("/courses/{course_id}/admin/assets/{folderName}")

    summary("Get a list of all assets in a folder")

    parameters do
      folderName(:path, :string, "Folder name", required: true)
    end

    security([%{JWT: []}])

    produces("application/json")

    response(200, "OK", :Assets)
    response(400, "Invalid folder name")
    response(403, "User is not allowed to manage assets")
  end

  swagger_path :delete do
    PhoenixSwagger.Path.delete("/courses/{course_id}/admin/assets/{folderName}/{fileName}")

    summary("Delete a file from an asset folder")

    parameters do
      folderName(:path, :string, "Folder name", required: true)

      fileName(:path, :string, "File path in folder, which may contain subfolders",
        required: true
      )
    end

    security([%{JWT: []}])

    response(204, "OK")
    response(400, "Invalid folder name, file name or file type")
    response(403, "User is not allowed to manage assets")
    response(404, "File not found")
  end

  swagger_path :upload do
    post("/courses/{course_id}/admin/assets/{folderName}/{fileName}")

    summary("Upload a file to an asset folder")

    parameters do
      folderName(:path, :string, "Folder name", required: true)

      fileName(:path, :string, "File path in folder, which may contain subfolders",
        required: true
      )
    end

    security([%{JWT: []}])

    produces("application/json")

    response(200, "OK", :AssetURL)
    response(400, "Invalid folder name, file name or file type")
    response(403, "User is not allowed to manage assets")
  end
end
