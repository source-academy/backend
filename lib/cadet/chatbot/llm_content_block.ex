defmodule Cadet.Chatbot.LlmContentBlock do
  @text_media_types ~w(text/x-tex application/xml text/xml)

  @spec build(String.t(), String.t(), String.t()) :: map()
  def build(filename, base64, media_type) do
    if media_type in @text_media_types do
      build_text_or_file(filename, base64, media_type)
    else
      file_block(filename, base64, media_type)
    end
  end

  defp build_text_or_file(filename, base64, media_type) do
    case Base.decode64(base64) do
      {:ok, decoded} ->
        if String.valid?(decoded) do
          %{type: "text", text: "Document: #{filename}\n\n#{decoded}"}
        else
          file_block(filename, base64, media_type)
        end

      :error ->
        file_block(filename, base64, media_type)
    end
  end

  defp file_block(filename, base64, media_type) do
    %{
      type: "file",
      file: %{filename: filename, file_data: "data:#{media_type};base64,#{base64}"}
    }
  end
end
