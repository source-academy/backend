defmodule CadetWeb.AssetsController do
  use CadetWeb, :controller

  use PhoenixSwagger
  alias Cadet.Assets

  @fetch_limit 1500

  def index(conn, _params = %{"foldername" => folder_name}) do
    with :ok <- Assets.validate_assets_role(conn),
         :ok <- Assets.validate_folder_name(folder_name)
    do
      assets = Assets.list_assets(folder_name, @fetch_limit)
      render(conn, "index.json", assets: assets)
    else
      {:error, {status, message}} -> conn|> put_status(status) |> text(message)
    end
  end


  def delete(conn, _params = %{"folderName" => folder_name, "filename"=> filename}) do
    with :ok <- Assets.validate_assets_role(conn),
         :ok <- Assets.validate_folder_name(folder_name)
    do
      Assets.delete_object(folder_name, filename)
      render(conn, "s3_response.json", resp: :ok)
    else
      {:error, {status, message}} -> conn |> put_status(status) |> text(message)
    end
  end

  def upload(conn, %{"upload" => upload_params, "details" => details}) do

    {:ok, details} = Jason.decode(details)
    %{"folderName" => folder_name, "filename" => filename} = details

    with :ok <- Assets.validate_assets_role(conn),
         :ok <- Assets.validate_folder_name(folder_name),
         :ok <- Assets.validate_filetype(filename)
    do
      filename = if Map.has_key?(details, "filename") do
        details["filename"]
      else
        upload_params.filename
      end

      resp = Assets.upload_to_s3(upload_params, folder_name, filename)
      render(conn, "s3_response.json", resp: resp)
    else
      {:error, {status, message}} -> conn |> put_status(status) |> text(message)
    end
  end


  swagger_path :index do
    get("/assets/:folder_name")

    summary("Get a list of all assets in a foldername")

    security([%{JWT: []}])

    produces("application/json")

    response(200, "OK")
    response(400, "Bad Request")
    response(401, "Unauthorised")
  end

  swagger_path :upload do
    post("/assets/upload")

    summary("Upload a file to an asset folder")

    security([%{JWT: []}])

    produces("application/json")

    response(200, "OK")
    response(400, "Bad Request")
    response(401, "Unauthorised")
  end

  swagger_path :delete do
    post("assets/delete")

    summary("Delete a file from an asset folder")

    security([%{JWT: []}])

    produces("application/json")

    response(200, "OK")
    response(400, "Bad Request")
    response(401, "Unauthorised")
  end

end
