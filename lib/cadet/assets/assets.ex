defmodule Cadet.Assets.Assets do
  @moduledoc """
  Assessments context contains domain logic for assets management
  for Source academy's game component
  """
  @manage_assets_role ~w(staff admin)a

  @accessible_folders ~w(images locations objects avatars ui stories testFolder)
  @accepted_file_types ~w(.jpg .jpeg .gif .JPG .txt .jpeg .wav .mp3 .png)

  @bucket_name "source-academy-assets"

  def validate_assets_role(conn) do
    if conn.assigns[:current_user].role in @manage_assets_role do
      :ok
    else
      {:error, {:forbidden, "User not allowed to manage assets"}}
    end
  end

  def validate_folder_name(folder_name) do
    if folder_name in @accessible_folders do
      :ok
    else
      {:error, {:bad_request, "Bad Request"}}
    end
  end

  def validate_filetype(filetype) do
    if filetype in @accepted_file_types do
      :ok
    else
      {:error, {:bad_request, "Invalid file type"}}
    end
  end

  def upload_to_s3(upload_params, folder_name, filename) do
    if does_object_exist(folder_name, filename) === :exists do
      {:error, {:bad_request, "File already exists"}}
    else
      file = upload_params.path

      s3_path = folder_name <> "/" <> filename

      file
      |> ExAws.S3.Upload.stream_file()
      |> ExAws.S3.upload(@bucket_name, s3_path)
      |> ExAws.request!()

      "http://#{@bucket_name}.s3.amazonaws.com/#{s3_path}"
    end
  end

  def list_assets(folder_name) do
    ExAws.S3.list_objects(@bucket_name, prefix: folder_name <> "/")
    |> ExAws.stream!()
    |> Enum.map(fn file -> file.key end)
  end

  def delete_object(folder_name, filename) do
    if does_object_exist(folder_name, filename) === :exists do
      ExAws.S3.delete_object(@bucket_name, folder_name <> "/" <> filename)
      |> ExAws.request!()

      :ok
    else
      {:error, {:bad_request, "No such file"}}
    end
  end

  @spec does_object_exist(binary, binary) :: :does_not_exist | :exists
  def does_object_exist(folder_name, filename) do
    with {:error, _error} <-
           ExAws.S3.head_object(@bucket_name, folder_name <> "/" <> filename)
           |> ExAws.request() do
      :does_not_exist
    else
      _resp -> :exists
    end
  end

  def filename_not_empty(filename) do
    if filename != "" do
      :ok
    else
      {:error, {:bad_request, "Empty file name"}}
    end
  end
end
