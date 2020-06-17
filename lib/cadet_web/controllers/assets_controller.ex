defmodule CadetWeb.AssetsController do
  use CadetWeb, :controller

  use PhoenixSwagger
  alias Cadet.Assets

  @manage_assets_role ~w(staff admin)a

  @accessible_folders ~w(images locations objects avatars ui stories testFolder)
  @accepted_file_types ~w(.jpg .jpeg .gif .JPG .txt .jpeg .wav .mp3 .png)

  @bucket_name "source-academy-assets"
  @fetch_limit 1500

  def index(conn, _params = %{"folder_name" => folder_name}) do
    validate_assets_role(conn)
    validate_folder_name(conn, folder_name)

    assets =
      ExAws.S3.list_objects(@bucket_name, [prefix: folder_name <> "/"])
      |> ExAws.stream!
      |> Enum.take(@fetch_limit)
    render(conn, "index.json", assets: assets)

  end


  def delete(conn, _params = %{"folder_name" => folder_name, "filename"=> filename}) do
    validate_assets_role(conn)
    validate_folder_name(conn, folder_name)

    s3_path = folder_name <> "/" <> filename

    ExAws.S3.delete_object(@bucket_name, s3_path)
      |> ExAws.request!

    resp = "ok"
    render(conn, "s3_response.json", resp: resp)

  end

  def upload(conn, %{"uploadParams" => upload_params, "details" => details}) do
    validate_assets_role(conn)

    {:ok, details} = Jason.decode(details)
    {:ok, folder_name} = Map.fetch(details, "folderName")
    validate_folder_name(conn, folder_name)

    resp = upload_to_s3(upload_params, folder_name)
    render(conn, "s3_response.json", resp: resp)
  end

  def upload_to_s3(upload_params, folder_name) do
    file = upload_params.path
    s3_path = folder_name <> "/" <> upload_params.filename

    file
      |> ExAws.S3.Upload.stream_file
      |> ExAws.S3.upload(@bucket_name, s3_path)
      |> ExAws.request!

    s3_url = "http://#{@bucket_name}.s3.amazonaws.com/#{s3_path}"
    %{
      s3_url: s3_url
    }
  end

  def validate_assets_role(conn) do
    role = conn.assigns[:current_user].role
    if not role in @manage_assets_role do
      conn
       |> put_status(:forbidden)
       |> text("User not allowed to upload assets")
    end
  end

  def validate_filetype(conn, filename) do
    if not Enum.member?(@accepted_file_types, Path.extname(filename)) do
      conn
      |> put_status(:bad_request)
      |> text("Bad file type")
    end
  end

  def validate_folder_name(conn, folder_name) do
    if not Enum.member?(@accessible_folders, folder_name) do
      conn
      |> put_status(:bad_request)
      |> text("No such folder")
    end
  end


end
