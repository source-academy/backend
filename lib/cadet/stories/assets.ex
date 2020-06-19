defmodule Cadet.Stories.Assets do
  @moduledoc """
  Assessments context contains domain logic for assets management
  for Source academy's game component
  """
  @manage_assets_role ~w(staff admin)a

  @accessible_folders ~w(images locations objects avatars ui stories testFolder)
  @accepted_file_types ~w(.jpg .jpeg .gif .JPG .txt .jpeg .wav .mp3 .png)

  @bucket_name "source-academy-assets"
  @fetch_limit 2000

  def validate_assets_role(conn) do
    if conn.assigns[:current_user].role in @manage_assets_role do
      :ok
    else
      {:error, {:forbidden, "User not allowed to manage assets"}}
    end
  end

  def validate_folder_name(folder_name) do
    if Enum.member?(@accessible_folders, folder_name) do
      :ok
    else
      {:error, {:bad_request, "Bad Request"}}
    end
  end

  def validate_filetype(filename) do
    if Enum.member?(@accepted_file_types, Path.extname(filename)) do
      :ok
    else
      {:error, {:bad_request, "Invalid file type"}}
    end
  end

  def upload_to_s3(upload_params, folder_name, filename) do
    file = upload_params.path

    s3_path = folder_name <> "/" <> filename

    file
    |> ExAws.S3.Upload.stream_file()
    |> ExAws.S3.upload(@bucket_name, s3_path)
    |> ExAws.request!()

    s3_url = "http://#{@bucket_name}.s3.amazonaws.com/#{s3_path}"

    %{
      s3_url: s3_url
    }
  end

  def list_assets(folder_name) do
    ExAws.S3.list_objects(@bucket_name, prefix: folder_name <> "/")
    |> ExAws.stream!()
    |> Enum.take(@fetch_limit)
    |> Enum.map(fn file -> file.key end)
  end

  def delete_object(folder_name, filename) do
    ExAws.S3.delete_object(@bucket_name, folder_name <> "/" <> filename)
    |> ExAws.request!()
  end
end
