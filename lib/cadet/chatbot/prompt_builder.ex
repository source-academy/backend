defmodule Cadet.Chatbot.PromptBuilder do
  @moduledoc """
  The PromptBuilder module is responsible for building the prompt for the chatbot.
  """

  alias Cadet.Chatbot.SicpNotes

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

  @routing_prompt """
  You are a document routing assistant. Given a student's question and a list of available course documents, determine which documents are most relevant to answering the question.

  Here is the list of available documents (JSON):
  %DOCUMENT_MAP%

  Instructions:
  - Return ONLY a JSON array of document IDs that are relevant to the student's question.
  - Select at most 5 documents.
  - If no documents are relevant (e.g. the question is about the SICP textbook only), return an empty array: []
  - Do NOT include any explanation, just the JSON array.

  Example response: ["cs1101s-final-2023", "cs1101s-midterm-2023"]
  Example response for no relevant documents: []
  """

  def build_routing_prompt(document_map_json) do
    map_string = Jason.encode!(document_map_json, pretty: true)
    String.replace(@routing_prompt, "%DOCUMENT_MAP%", map_string)
  end

  @rag_answer_prompt """
  You are a competent tutor assisting a computer science student on the Source Academy platform.

  You have been provided with relevant course documents (exams, lecture slides, tutorial sheets, or recitation sheets) as PDF attachments. Use these documents to answer the student's question.

  CRITICAL INSTRUCTIONS:
  - Answer using ONLY the provided documents. Do not make up information.
  - When citing information from a document, mention the document title and year.
  - If the provided documents do not contain enough information to answer, say so clearly.
  - The Source Academy platform uses the "Source" language, a restricted subset of JavaScript. When providing code examples, use valid Source language syntax.
  - Do NOT use JavaScript features not supported in Source (classes, modules, imports/exports, async/await, generators).
  - Use display or display_list instead of console.log.

  Please answer the student's question using the attached documents.
  """

  def build_rag_answer_prompt do
    @rag_answer_prompt
  end
end
