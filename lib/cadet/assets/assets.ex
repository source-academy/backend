defmodule Cadet.Assets.Assets do
  alias ExAws.{S3, S3.Upload}

  @moduledoc """
  Assessments context contains domain logic for assets management
  for Source academy's game component
  """
  @accessible_folders ~w(images locations objects avatars ui stories sfx bgm) ++
                        if(Mix.env() == :test, do: ["testFolder"], else: [])
  @accepted_file_types ~w(.jpg .jpeg .gif .png .wav .mp3 .txt)

  def upload_to_s3(upload_params, prefix, folder_name, file_name) do
    file_type = Path.extname(file_name)

    with :ok <- validate_file_name(file_name),
         :ok <- validate_folder_name(folder_name),
         :ok <- validate_file_type(file_type) do
      if object_exists?(prefix, folder_name, file_name) do
        {:error, {:bad_request, "File already exists"}}
      else
        file = upload_params.path

        s3_path = "#{prefix}#{folder_name}/#{file_name}"

        file
        |> Upload.stream_file()
        |> S3.upload(bucket(), s3_path)
        |> ExAws.request!()

        "https://#{bucket()}.s3.amazonaws.com/#{s3_path}"
      end
    end
  end

  def list_assets(prefix, folder_name) do
    prefix_len = byte_size(prefix)

    case validate_folder_name(folder_name) do
      :ok ->
        bucket()
        |> S3.list_objects(prefix: prefix <> folder_name <> "/")
        |> ExAws.stream!()
        |> Enum.map(fn file ->
          binary_part(file.key, prefix_len, byte_size(file.key) - prefix_len)
        end)

      {:error, _} = error ->
        error
    end
  end

  def delete_object(prefix, folder_name, file_name) do
    with :ok <- validate_file_name(file_name),
         :ok <- validate_folder_name(folder_name) do
      if object_exists?(prefix, folder_name, file_name) do
        bucket()
        |> S3.delete_object("#{prefix}#{folder_name}/#{file_name}")
        |> ExAws.request!()

        :ok
      else
        {:error, {:not_found, "File not found"}}
      end
    end
  end

  @spec object_exists?(integer() | binary(), binary, binary) :: boolean()
  def object_exists?(prefix, folder_name, file_name) do
    response =
      bucket()
      |> S3.head_object("#{prefix}#{folder_name}/#{file_name}")
      |> ExAws.request()

    case response do
      {:error, _error} -> false
      _ -> true
    end
  end

  defp validate_folder_name(folder_name) do
    if folder_name in @accessible_folders do
      :ok
    else
      {:error, {:bad_request, "Invalid top-level folder name"}}
    end
  end

  defp validate_file_type(file_type) do
    if String.downcase(file_type) in @accepted_file_types do
      :ok
    else
      {:error, {:bad_request, "Invalid file type"}}
    end
  end

  defp validate_file_name(file_name) do
    if file_name != "" do
      :ok
    else
      {:error, {:bad_request, "Empty file name"}}
    end
  end

  defp bucket, do: :cadet |> Application.fetch_env!(:uploader) |> Keyword.get(:assets_bucket)

  def assets_prefix,
    do: :cadet |> Application.fetch_env!(:uploader) |> Keyword.get(:assets_prefix, "")
end
