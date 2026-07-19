alias Cadet.Chatbot.{PromptBuilder, RagEvaluation, VectorRetriever}

Logger.configure(level: :info)

defmodule Cadet.RagEvaluationScript do
  @moduledoc false

  def first_answer([first | _]), do: get_in(first, ["message", "content"])
  def first_answer(_choices), do: nil

  def citation_ok?(_answer, %{require_section_reference: false}), do: true

  def citation_ok?(answer, case_data),
    do: RagEvaluation.answer_mentions_expected_section?(answer, case_data)

  def chunk_report(chunk) do
    metadata = chunk.metadata || %{}

    %{
      id: chunk.id,
      chunk_index: chunk.chunk_index,
      title: chunk.title,
      source_filename: chunk.source_filename,
      section: RagEvaluation.chunk_section(chunk),
      section_title: Map.get(metadata, "section_title") || Map.get(metadata, :section_title),
      similarity: chunk.similarity,
      preview: chunk.content |> String.replace(~r/\s+/, " ") |> String.slice(0, 500)
    }
  end

  def format_similarity(nil), do: "nil"
  def format_similarity(similarity), do: :erlang.float_to_binary(similarity, decimals: 4)
end

defaults = [
  course_id: 1,
  language: "python",
  limit: 5,
  model: System.get_env("RAG_EVAL_MODEL") || "gpt-4",
  output: nil,
  fail_on_miss: false,
  only: nil
]

argv =
  case System.argv() do
    ["--" | rest] -> rest
    args -> args
  end

{opts, _argv, invalid} =
  OptionParser.parse(argv,
    strict: [
      course_id: :integer,
      language: :string,
      limit: :integer,
      model: :string,
      output: :string,
      fail_on_miss: :boolean,
      only: :string
    ]
  )

if invalid != [] do
  IO.puts(:stderr, "Invalid options: #{inspect(invalid)}")
  System.halt(2)
end

opts = Keyword.merge(defaults, opts)

cases =
  RagEvaluation.cases()
  |> Enum.filter(fn case_data ->
    only = Keyword.fetch!(opts, :only)
    is_nil(only) or case_data.id == only or Integer.to_string(case_data.chapter) == only
  end)

if cases == [] do
  IO.puts(:stderr, "No evaluation cases matched --only=#{inspect(Keyword.fetch!(opts, :only))}")
  System.halt(2)
end

openai_config = %OpenAI.Config{http_options: [timeout: 60_000, recv_timeout: 60_000]}

IO.puts("""
Running #{length(cases)} RAG evaluation case(s)
course_id=#{Keyword.fetch!(opts, :course_id)} language=#{Keyword.fetch!(opts, :language)} top_k=#{Keyword.fetch!(opts, :limit)} model=#{Keyword.fetch!(opts, :model)}
""")

results =
  Enum.map(cases, fn case_data ->
    IO.puts("\n================================================================================")

    IO.puts(
      "#{case_data.id} | Chapter #{case_data.chapter} | expected #{Enum.join(case_data.expected_sections, ", ")}"
    )

    IO.puts("Question: #{case_data.question}")

    retrieval =
      VectorRetriever.retrieve(case_data.question,
        course_id: Keyword.fetch!(opts, :course_id),
        language: Keyword.fetch!(opts, :language),
        limit: Keyword.fetch!(opts, :limit)
      )

    case retrieval do
      {:ok, chunks} ->
        retrieval_hit = RagEvaluation.retrieval_hits_expected_section?(chunks, case_data)

        IO.puts("\nTop matched chunks:")

        chunks
        |> Enum.with_index(1)
        |> Enum.each(fn {chunk, rank} ->
          metadata = chunk.metadata || %{}
          section = RagEvaluation.chunk_section(chunk) || "none"

          section_title =
            Map.get(metadata, "section_title") || Map.get(metadata, :section_title) || ""

          similarity = Cadet.RagEvaluationScript.format_similarity(chunk.similarity)
          preview = chunk.content |> String.replace(~r/\s+/, " ") |> String.slice(0, 280)

          IO.puts(
            "#{rank}. score=#{similarity} section=#{section} #{section_title} chunk=#{chunk.chunk_index} id=#{chunk.id}"
          )

          IO.puts("   #{preview}")
        end)

        system_prompt =
          PromptBuilder.build_prompt(case_data.current_section, "", chunks) <>
            RagEvaluation.citation_instruction(case_data)

        payload = [
          %{role: "system", content: system_prompt},
          %{role: "user", content: case_data.question}
        ]

        answer_result =
          OpenAI.chat_completion(
            [model: Keyword.fetch!(opts, :model), messages: payload],
            openai_config
          )

        case answer_result do
          {:ok, result_map} ->
            answer =
              result_map |> Map.get(:choices, []) |> Cadet.RagEvaluationScript.first_answer()

            citation_ok = Cadet.RagEvaluationScript.citation_ok?(answer, case_data)

            IO.puts("\nFinal API answer:")
            IO.puts(answer || "<empty answer>")

            IO.puts(
              "\nChecks: retrieval_expected_section=#{retrieval_hit} section_citation=#{citation_ok}"
            )

            %{
              id: case_data.id,
              question: case_data.question,
              expected_sections: case_data.expected_sections,
              require_section_reference: case_data.require_section_reference,
              retrieval_expected_section: retrieval_hit,
              section_citation: citation_ok,
              top_chunks: Enum.map(chunks, &Cadet.RagEvaluationScript.chunk_report/1),
              answer: answer
            }

          {:error, reason} ->
            IO.puts(:stderr, "\nOpenAI error: #{inspect(reason)}")

            %{
              id: case_data.id,
              question: case_data.question,
              expected_sections: case_data.expected_sections,
              require_section_reference: case_data.require_section_reference,
              retrieval_expected_section: retrieval_hit,
              section_citation: false,
              top_chunks: Enum.map(chunks, &Cadet.RagEvaluationScript.chunk_report/1),
              answer: nil,
              error: inspect(reason)
            }
        end

      {:error, reason} ->
        IO.puts(:stderr, "\nRetrieval error: #{inspect(reason)}")

        %{
          id: case_data.id,
          question: case_data.question,
          expected_sections: case_data.expected_sections,
          require_section_reference: case_data.require_section_reference,
          retrieval_expected_section: false,
          section_citation: false,
          top_chunks: [],
          answer: nil,
          error: inspect(reason)
        }
    end
  end)

summary = %{
  total: length(results),
  retrieval_hits: Enum.count(results, & &1.retrieval_expected_section),
  required_citations: Enum.count(results, fn result -> result.require_section_reference end),
  citation_hits:
    Enum.count(results, fn result ->
      not result.require_section_reference or result.section_citation
    end),
  failures:
    Enum.filter(results, fn result ->
      not result.retrieval_expected_section or
        (result.require_section_reference and not result.section_citation) or
        Map.has_key?(result, :error)
    end)
    |> Enum.map(& &1.id)
}

report = %{
  generated_at: DateTime.utc_now() |> DateTime.to_iso8601(),
  options: Enum.into(opts, %{}),
  summary: summary,
  results: results
}

IO.puts("\n================================================================================")
IO.puts("Summary: #{Jason.encode!(summary)}")

if output = Keyword.fetch!(opts, :output) do
  output |> Path.dirname() |> File.mkdir_p!()
  File.write!(output, Jason.encode!(report, pretty: true))
  IO.puts("Wrote JSON report to #{output}")
end

if Keyword.fetch!(opts, :fail_on_miss) and summary.failures != [] do
  System.halt(1)
end
