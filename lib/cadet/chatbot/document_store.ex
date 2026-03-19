defmodule Cadet.Chatbot.DocumentStore do
  require Logger

  def fetch_document_binary(document) when is_map(document) do
    config = rag_config()
    bucket = config[:bucket]
    s3_key = document["s3_key"]
    region = config[:region]

    Logger.info("Fetching document from S3: #{bucket}/#{s3_key} (region: #{region})")

    ExAws.S3.get_object(bucket, s3_key)
    |> ExAws.request(
      access_key_id: config[:access_key_id],
      secret_access_key: config[:secret_access_key],
      region: region,
      host: "s3.#{region}.amazonaws.com",
      scheme: "https://"
    )
    |> case do
      {:ok, %{body: body}} ->
        Logger.info("Successfully fetched document #{s3_key} (#{byte_size(body)} bytes)")
        {:ok, body}

      {:error, reason} ->
        Logger.error("Failed to fetch document #{s3_key}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def encode_document_base64(document) when is_map(document) do
    case fetch_document_binary(document) do
      {:ok, binary} -> {:ok, Base.encode64(binary)}
      {:error, reason} -> {:error, reason}
    end
  end

  def fetch_and_encode_documents(documents) when is_list(documents) do
    documents
    |> Enum.reduce([], fn doc, acc ->
      case encode_document_base64(doc) do
        {:ok, base64} ->
          attachment = %{
            title: doc["title"],
            base64: base64,
            media_type: media_type_for(doc["s3_key"])
          }

          [attachment | acc]

        {:error, reason} ->
          Logger.warning("Skipping document #{doc["id"]}: #{inspect(reason)}")

          acc
      end
    end)
    |> Enum.reverse()
  end

  defp media_type_for(s3_key) do
    case Path.extname(s3_key) do
      ".pdf" -> "application/pdf"
      ".pptx" -> "application/vnd.openxmlformats-officedocument.presentationml.presentation"
      ".docx" -> "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      _ -> "application/octet-stream"
    end
  end

  defp rag_config do
    Application.fetch_env!(:cadet, :rag_documents)
  end
end
