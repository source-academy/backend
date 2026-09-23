defmodule Cadet.Chatbot.MetadataGenerator do
  @moduledoc """
  Asks an LLM to propose a description for a freshly-uploaded pixelbot document.
  """
  require Logger

  alias Cadet.Chatbot.CourseLlm

  @system_prompt """
  You are cataloging a course document for a university course assistant chatbot named Pixel.
  Pixel reads your description (without the file itself) to decide whether this document is
  relevant to a student's question, so it must be specific and content-focused, not generic.

  Given the attached file, respond with ONLY a JSON object of the form:

  {"description": "..."}

  - description: 1-2 sentences, at most 40 words, naming the actual topics, concepts, functions,
    or problem types covered — the specific technical terms a student might ask about (e.g.
    "Covers recursion, the substitution model, and tail calls; includes practice problems on
    writing recursive list-processing functions."). Do NOT write generic filler like "This
    document contains a task" or "This is a course document about programming" — skip straight
    to the content. If the document is an assignment or quiz, name the concepts it tests, not
    just that it has questions.

  Do NOT include any explanation outside the JSON object.
  """

  @spec generate(String.t(), String.t(), String.t(), String.t(), CourseLlm.t()) :: map()
  def generate(filename, base64, media_type, model, llm_config) do
    payload = [
      %{role: "system", content: @system_prompt},
      %{
        role: "user",
        content: [Cadet.Chatbot.LlmContentBlock.build(filename, base64, media_type)]
      }
    ]

    case OpenAI.chat_completion([model: model, messages: payload], llm_config) do
      {:ok, result_map} ->
        result_map
        |> extract_content()
        |> parse_metadata()
        |> fallback(filename)

      {:error, reason} ->
        Logger.warning("Pixelbot metadata generation failed for #{filename}: #{inspect(reason)}")
        fallback(%{}, filename)
    end
  end

  defp extract_content(result_map) do
    case Map.get(result_map, :choices, []) do
      [first | _] -> first["message"]["content"]
      _ -> nil
    end
  end

  defp parse_metadata(nil), do: %{}

  defp parse_metadata(content) do
    trimmed = String.trim(content)

    case Jason.decode(trimmed) do
      {:ok, map} when is_map(map) ->
        map

      _ ->
        case Regex.run(~r/\{.*\}/s, trimmed) do
          [json_str] ->
            case Jason.decode(json_str) do
              {:ok, map} when is_map(map) -> map
              _ -> %{}
            end

          nil ->
            %{}
        end
    end
  end

  defp fallback(metadata, filename) do
    %{
      title: Path.rootname(filename),
      description: presence(metadata["description"]) || ""
    }
  end

  defp presence(nil), do: nil
  defp presence(""), do: nil
  defp presence(value), do: value
end
