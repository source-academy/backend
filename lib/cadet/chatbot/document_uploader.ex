defmodule Cadet.Chatbot.DocumentUploader do
  @moduledoc """
  Uploads and deletes pixelbot course documents in S3.
  """
  require Logger

  alias Cadet.Chatbot.Slug

  @accepted_extensions ~w(.pdf .pptx .docx .tex .xml)
  @max_upload_bytes 10_000_000

  def accepted_extensions, do: @accepted_extensions

  @spec upload(String.t(), Path.t(), integer(), MapSet.t(String.t())) ::
          {:ok, %{s3_key: String.t(), media_type: String.t()}}
          | {:error, {:bad_request, String.t()}}
  def upload(filename, tmp_path, course_id, claimed_keys \\ MapSet.new()) do
    ext = filename |> Path.extname() |> String.downcase()

    with :ok <- validate_extension(ext),
         :ok <- validate_size(tmp_path) do
      base_name = "course-#{course_id}/#{Slug.slugify(Path.rootname(filename))}"

      s3_key =
        Slug.unique(base_name, fn candidate ->
          candidate_key = candidate <> ext
          MapSet.member?(claimed_keys, candidate_key) or object_exists?(candidate_key)
        end) <> ext

      case do_upload(tmp_path, s3_key) do
        :ok -> {:ok, %{s3_key: s3_key, media_type: media_type_for(ext)}}
        {:error, reason} -> {:error, {:bad_request, "Failed to upload to S3: #{inspect(reason)}"}}
      end
    end
  end

  defp validate_extension(ext) do
    if ext in @accepted_extensions do
      :ok
    else
      {:error, {:bad_request, "Unsupported file type #{ext}"}}
    end
  end

  defp validate_size(tmp_path) do
    case File.stat(tmp_path) do
      {:ok, %File.Stat{size: size}} when size > @max_upload_bytes ->
        {:error,
         {:bad_request,
          "File is #{megabytes(size)} MB, which exceeds the #{megabytes(@max_upload_bytes)} MB limit"}}

      {:ok, _stat} ->
        :ok

      {:error, reason} ->
        {:error, {:bad_request, "Could not read uploaded file: #{inspect(reason)}"}}
    end
  end

  defp megabytes(bytes), do: Float.round(bytes / 1_000_000, 1)

  @doc """
  Moves a document to a new S3 key derived from `new_filename`, copying then deleting the old
  object. Returns the new key/media type on success. If the delete of the old key fails after
  the copy succeeds, the old object is left behind for the orphan sweeper to reclaim later —
  the document row already points at the new key, so nothing is broken.
  """
  @spec rename(String.t(), String.t(), integer()) ::
          {:ok, %{s3_key: String.t(), media_type: String.t()}}
          | {:error, {:bad_request, String.t()}}
  def rename(old_s3_key, new_filename, course_id) do
    ext = Path.extname(new_filename) |> String.downcase()

    if ext in @accepted_extensions do
      base_name = "course-#{course_id}/#{Slug.slugify(Path.rootname(new_filename))}"

      new_key =
        Slug.unique(base_name, fn candidate ->
          candidate_key = candidate <> ext
          candidate_key != old_s3_key and object_exists?(candidate_key)
        end) <> ext

      if new_key == old_s3_key do
        {:ok, %{s3_key: new_key, media_type: media_type_for(ext)}}
      else
        do_rename(old_s3_key, new_key, ext)
      end
    else
      {:error, {:bad_request, "Unsupported file type #{ext}"}}
    end
  end

  @doc false
  @spec restore_rename(String.t(), String.t()) ::
          :ok | {:error, {:bad_request, String.t()}}
  def restore_rename(new_key, old_key) do
    case copy_object(new_key, old_key) do
      {:ok, _} ->
        delete(new_key)
        :ok

      {:error, reason} ->
        Logger.error("Failed to restore #{new_key} -> #{old_key}: #{inspect(reason)}")
        {:error, {:bad_request, "Failed to restore document in S3"}}
    end
  end

  @spec delete(String.t()) :: :ok
  def delete(s3_key) do
    config = rag_config()

    config[:bucket]
    |> ExAws.S3.delete_object(s3_key)
    |> ExAws.request(request_opts(config))
    |> case do
      {:ok, _} ->
        :ok

      {:error, reason} ->
        Logger.error("Failed to delete pixelbot document #{s3_key}: #{inspect(reason)}")
        :ok
    end
  end

  defp do_upload(tmp_path, s3_key) do
    config = rag_config()

    with {:ok, contents} <- File.read(tmp_path) do
      config[:bucket]
      |> ExAws.S3.put_object(s3_key, contents)
      |> ExAws.request(request_opts(config))
      |> case do
        {:ok, _} -> :ok
        {:error, reason} -> {:error, reason}
      end
    end
  end

  defp do_rename(old_key, new_key, ext) do
    case copy_object(old_key, new_key) do
      {:ok, _} ->
        delete(old_key)
        {:ok, %{s3_key: new_key, media_type: media_type_for(ext)}}

      {:error, reason} ->
        Logger.error("Failed to copy #{old_key} -> #{new_key}: #{inspect(reason)}")
        {:error, {:bad_request, "Failed to rename document in S3"}}
    end
  end

  defp copy_object(source_key, destination_key) do
    config = rag_config()
    bucket = config[:bucket]

    bucket
    |> ExAws.S3.put_object_copy(destination_key, bucket, source_key)
    |> ExAws.request(request_opts(config))
  end

  defp object_exists?(s3_key) do
    config = rag_config()

    response =
      config[:bucket]
      |> ExAws.S3.head_object(s3_key)
      |> ExAws.request(request_opts(config))

    case response do
      {:ok, _} ->
        true

      {:error, {:http_error, 404, _}} ->
        false

      {:error, reason} ->
        Logger.warning(
          "Could not verify whether pixelbot S3 object #{s3_key} exists; " <>
            "treating it as occupied: #{inspect(reason)}"
        )

        true
    end
  end

  defp media_type_for(".pdf"), do: "application/pdf"

  defp media_type_for(".pptx"),
    do: "application/vnd.openxmlformats-officedocument.presentationml.presentation"

  defp media_type_for(".docx"),
    do: "application/vnd.openxmlformats-officedocument.wordprocessingml.document"

  defp media_type_for(".tex"), do: "text/x-tex"

  defp media_type_for(".xml"), do: "application/xml"

  defp media_type_for(_), do: "application/octet-stream"

  defp request_opts(config) do
    region = config[:region]
    [region: region, host: "s3.#{region}.amazonaws.com", scheme: "https://"]
  end

  defp rag_config do
    Application.fetch_env!(:cadet, :rag_documents)
  end
end
