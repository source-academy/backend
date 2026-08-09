defmodule Cadet.Chatbot.DocumentUploader do
  @moduledoc """
  Uploads and deletes pixelbot course documents in S3.
  """
  require Logger

  alias Cadet.Chatbot.Slug

  @accepted_extensions ~w(.pdf .pptx .docx .tex .xml)

  def accepted_extensions, do: @accepted_extensions

  @spec upload(String.t(), Path.t(), integer(), MapSet.t(String.t())) ::
          {:ok, %{s3_key: String.t(), media_type: String.t()}}
          | {:error, {:bad_request, String.t()}}
  def upload(filename, tmp_path, course_id, claimed_keys \\ MapSet.new()) do
    ext = Path.extname(filename) |> String.downcase()

    if ext in @accepted_extensions do
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
    else
      {:error, {:bad_request, "Unsupported file type #{ext}"}}
    end
  end

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
        Slug.unique(base_name, fn candidate -> object_exists?(candidate <> ext) end) <> ext

      if new_key == old_s3_key do
        {:ok, %{s3_key: new_key, media_type: media_type_for(ext)}}
      else
        do_rename(old_s3_key, new_key, ext)
      end
    else
      {:error, {:bad_request, "Unsupported file type #{ext}"}}
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

    tmp_path
    |> ExAws.S3.Upload.stream_file()
    |> ExAws.S3.upload(config[:bucket], s3_key)
    |> ExAws.request(request_opts(config))
    |> case do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp do_rename(old_key, new_key, ext) do
    config = rag_config()
    bucket = config[:bucket]

    copy_result =
      bucket
      |> ExAws.S3.put_object_copy(new_key, bucket, old_key)
      |> ExAws.request(request_opts(config))

    case copy_result do
      {:ok, _} ->
        delete(old_key)
        {:ok, %{s3_key: new_key, media_type: media_type_for(ext)}}

      {:error, reason} ->
        Logger.error("Failed to copy #{old_key} -> #{new_key}: #{inspect(reason)}")
        {:error, {:bad_request, "Failed to rename document in S3"}}
    end
  end

  defp object_exists?(s3_key) do
    config = rag_config()

    response =
      config[:bucket]
      |> ExAws.S3.head_object(s3_key)
      |> ExAws.request(request_opts(config))

    case response do
      {:error, _} -> false
      _ -> true
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
