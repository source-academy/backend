defmodule Cadet.Chatbot.LlmContentBlock do
  @text_media_types ~w(text/x-tex application/xml text/xml)

  @spec build(String.t(), String.t(), String.t()) :: map()
  def build(filename, base64, media_type) when media_type in @text_media_types do
    %{type: "text", text: "Document: #{filename}\n\n#{Base.decode64!(base64)}"}
  end

  def build(filename, base64, media_type) do
    %{
      type: "file",
      file: %{filename: filename, file_data: "data:#{media_type};base64,#{base64}"}
    }
  end
end
