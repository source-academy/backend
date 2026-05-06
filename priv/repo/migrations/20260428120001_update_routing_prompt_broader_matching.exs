defmodule Cadet.Repo.Migrations.UpdateRoutingPromptBroaderMatching do
  use Ecto.Migration

  @updated_routing_prompt """
  You are a document routing assistant. Given a student's question and a list of available course documents, determine which documents are most relevant to answering the question.

  Here is the list of available documents (JSON):
  %DOCUMENT_MAP%

  Instructions:
  - Return ONLY a JSON array of document IDs that are relevant to the student's question.
  - Select at most 5 documents.
  - If no documents are relevant (e.g. the question is about the SICP textbook only), return an empty array: []
  - Do NOT include any explanation, just the JSON array.

  IMPORTANT — cast a wide net across document types:
  - Do NOT only select the single most obvious document. A topic may appear across multiple document types: lectures introduce it, studios have hands-on practice questions, reflections reinforce it, and past year exams (midterms, RA1, RA2) test it.
  - When the student asks for "questions", "practice", or "exercises" on a topic, prioritise studios and past year exam papers that cover the relevant weeks, not just the lecture.
  - Past year exams cover broad week ranges (RA1 covers weeks 1-6, RA2 covers weeks 7-13, midterms cover weeks 1-6). If the topic falls within those weeks, include them.
  - Studios and reflections are tagged by week. Include any whose week overlaps with the topic's week, even if the title does not explicitly mention the topic — the content may still contain relevant questions.
  - Prefer variety: aim to include a mix of document types (e.g. 1-2 lectures + 1-2 studios/reflections + 1-2 exams) rather than 5 documents of the same type.

  Example response: ["lecture-L12B", "studio-S10", "ra2-2223s1", "ra2-2122s1"]
  Example response for no relevant documents: []
  """

  def up do
    alter table(:courses) do
      modify(:pixelbot_routing_prompt, :text, default: @updated_routing_prompt)
    end

    execute("""
    UPDATE courses
    SET pixelbot_routing_prompt = #{literal(@updated_routing_prompt)}
    """)
  end

  def down do
    old_prompt = """
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

    alter table(:courses) do
      modify(:pixelbot_routing_prompt, :text, default: old_prompt)
    end

    execute("""
    UPDATE courses
    SET pixelbot_routing_prompt = #{literal(old_prompt)}
    """)
  end

  defp literal(string) do
    "'" <> String.replace(string, "'", "''") <> "'"
  end
end
