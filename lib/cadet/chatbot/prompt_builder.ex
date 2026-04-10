defmodule Cadet.Chatbot.PromptBuilder do
  @moduledoc """
  The PromptBuilder module is responsible for building the prompt for the chatbot.
  """

  require Logger

  alias Cadet.Chatbot.SicpNotes

  @document_map_placeholder "%DOCUMENT_MAP%"

  @prompt_prefix """
  You are a competent tutor, assisting a student who is learning computer science following the textbook "Structure and Interpretation of Computer Programs, JavaScript edition" (SICP JS) on the Source Academy platform. The student request is about a paragraph of the book. The request may be a follow-up request to a request that was posed to you previously.

  CRITICAL: The Source Academy platform uses the "Source" language, which is a restricted subset of JavaScript. When you provide code examples, you MUST use valid Source language syntax. Follow these rules strictly:
  - Do NOT use any JavaScript features that are not supported in Source. This includes, but is not limited to, classes, modules, imports/exports, async/await, generators, and certain built-in objects and methods.
  - Use display or display_list instead of console.log to print output.

  If you are unsure whether a JavaScript feature is available in Source, do NOT use it. Always make sure the code you give can run in the Source Academy Playground.

  What follows are:
  (1) the summary of section (2) the full paragraph. Please answer the student request,
  not the requests of the history. If the student request is not related to the book, ask them to ask questions that are related to the book. Do not say that I provide you text.

  """

  @query_prefix "\n(2) Here is the paragraph:\n"

  def build_prompt(section, context) do
    section_summary = SicpNotes.get_summary(section)

    section_prefix =
      case section_summary do
        nil ->
          "\n(1) There is no section summary for this section. Please answer the question based on the following paragraph.\n"

        summary ->
          "\n(1) Here is the summary of this section:\n" <> summary
      end

    @prompt_prefix <> section_prefix <> @query_prefix <> context
  end

  def build_routing_prompt(document_map_json, prompt) when is_binary(prompt) and prompt != "" do
    map_string = Jason.encode!(document_map_json, pretty: true)

    if String.contains?(prompt, @document_map_placeholder) do
      {:ok, String.replace(prompt, @document_map_placeholder, map_string)}
    else
      Logger.error(
        "PromptBuilder: routing prompt is missing the #{@document_map_placeholder} " <>
          "placeholder. The document map cannot be injected. Please update the course's " <>
          "pixelbot_routing_prompt to include #{@document_map_placeholder}."
      )

      {:error, :missing_document_map_placeholder}
    end
  end

  def build_routing_prompt(_document_map_json, _prompt) do
    Logger.error("PromptBuilder: routing prompt is missing or empty")
    {:error, :empty_routing_prompt}
  end
end
