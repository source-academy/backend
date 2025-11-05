defmodule Cadet.Updater.XMLParser do
  @moduledoc """
  Parser for XML files from the cs1101s repository.
  """

  use Cadet, [:display]

  import Ecto.Query
  import SweetXml

  alias Cadet.{Repo, Courses.AssessmentConfig, Assessments, SharedHelper}

  require Logger

  defmacrop is_non_empty_list(term) do
    quote do: is_list(unquote(term)) and unquote(term) != []
  end

  @spec parse_xml(String.t(), integer(), integer(), boolean()) ::
          :ok | {:ok, String.t()} | {:error, {atom(), String.t()}}
  def parse_xml(xml, course_id, assessment_config_id, force_update \\ false) do
    with {:ok, assessment_params} <- process_assessment(xml, course_id, assessment_config_id),
         {:ok, questions_params} <- process_questions(xml),
         {:ok, %{assessment: assessment}} <-
           Assessments.insert_or_update_assessments_and_questions(
             assessment_params,
             questions_params,
             force_update
           ) do
      Logger.info(
        "Created/updated assessment with id: #{assessment.id}, with #{length(questions_params)} questions."
      )

      :ok
    else
      {:error, stage, %{errors: [assessment: {"has submissions", []}]}, _} when is_atom(stage) ->
        Logger.warning("Assessment has submissions, ignoring...")
        {:ok, "Assessment has submissions, ignoring..."}

      {:error, error_message} ->
        log_and_return_badrequest(error_message)

      {:error, stage, changeset, _} ->
        log_error_bad_changeset(changeset, stage)

        changeset_error =
          changeset
          |> Map.get(:errors)
          |> extract_changeset_error_message

        error_message = "Invalid #{stage} changeset #{changeset_error}"
        log_and_return_badrequest(error_message)
    end
  catch
    # the :erlsom library used by SweetXml will exit if XML is invalid
    :exit, parse_error ->
      # error info is stored in multiple nested tuples
      error_message =
        parse_error
        |> nested_tuple_to_list()
        |> List.flatten()
        |> Enum.reduce("", fn x, acc -> "#{acc <> to_string(x)} " end)

      {:error, {:bad_request, "Invalid XML #{error_message}"}}
  end

  defp extract_changeset_error_message(errors_list) do
    errors_list
    |> Enum.map(fn {field, {error, _}} -> "#{to_string(field)} #{error}" end)
    |> List.foldr("", fn x, acc -> "#{acc <> x} " end)
  end

  @spec process_assessment(String.t(), integer(), integer()) ::
          {:ok, map()} | {:error, String.t()}
  defp process_assessment(xml, course_id, assessment_config_id) do
    open_at =
      Timex.now()
      |> Timex.beginning_of_day()
      |> Timex.shift(days: 3)
      |> Timex.shift(hours: 4)

    close_at = Timex.shift(open_at, days: 7)

    assessment_config =
      AssessmentConfig
      |> where(id: ^assessment_config_id)
      |> Repo.one()

    assessment_params =
      xml
      |> xpath(
        ~x"//TASK"e,
        access: ~x"./@access"s |> transform_by(&process_access/1),
        title: ~x"./@title"s,
        number: ~x"./@number"s,
        story: ~x"./@story"s,
        cover_picture: ~x"./@coverimage"s,
        reading: ~x"//READING/text()" |> transform_by(&process_charlist/1),
        summary_short: ~x"//WEBSUMMARY/text()" |> transform_by(&process_charlist/1),
        summary_long: ~x"./TEXT/text()" |> transform_by(&process_charlist/1),
        llm_assessment_prompt:
          ~x"./LLM_ASSESSMENT_PROMPT/text()" |> transform_by(&process_charlist/1),
        password: ~x"//PASSWORD/text()"so |> transform_by(&process_charlist/1)
      )
      |> Map.put(:is_published, false)
      |> Map.put(:open_at, open_at)
      |> Map.put(:close_at, close_at)
      |> Map.put(:course_id, course_id)
      |> Map.put(:config_id, assessment_config_id)
      |> Map.put(:has_token_counter, assessment_config.has_token_counter)
      |> Map.put(:has_voting_features, assessment_config.has_voting_features)
      |> (&if(&1.access === "public",
            do: Map.put(&1, :password, nil),
            else: &1
          )).()
      |> (&if(&1.access === "private" and &1.password === nil,
            do: Map.put(&1, :password, ""),
            else: &1
          )).()

    {:ok, assessment_params}
  rescue
    # This error is raised by xpath/3 when TASK does not exist (hence is equal to nil)
    Protocol.UndefinedError ->
      {:error, "Missing TASK"}
  end

  def process_access("private") do
    "private"
  end

  def process_access(_) do
    "public"
  end

  @spec process_questions(String.t()) :: {:ok, [map()]} | {:error, String.t()}
  defp process_questions(xml) do
    default_library = xpath(xml, ~x"//TASK/PROGRAMMINGLANGUAGE"e)
    default_grading_library = xpath(xml, ~x"//TASK/GRADERPROGRAMMINGLANGUAGE"e)

    questions_params =
      xml
      |> xpath(
        ~x"//PROBLEMS/PROBLEM"el,
        type: ~x"./@type"o |> transform_by(&process_charlist/1),
        max_xp: ~x"./@maxxp"oi,
        show_solution: ~x"./@showsolution"os,
        blocking: ~x"./@blocking"os,
        entity: ~x"."
      )
      |> Enum.map(fn param ->
        with {:no_missing_attr?, true} <-
               {:no_missing_attr?, not is_nil(param[:type]) and not is_nil(param[:max_xp])},
             question when is_map(question) <-
               SharedHelper.process_map_booleans(param, [:show_solution, :blocking]),
             question when is_map(question) <- process_question_by_question_type(param),
             question when is_map(question) <-
               process_question_library(question, default_library, default_grading_library),
             question when is_map(question) <- Map.delete(question, :entity) do
          question
        else
          {:no_missing_attr?, false} ->
            {:error, "Missing attribute(s) on PROBLEM"}

          {:error, error_message} ->
            {:error, error_message}
        end
      end)

    if Enum.any?(questions_params, &(!is_map(&1))) do
      error = Enum.find(questions_params, &(!is_map(&1)))
      error
    else
      {:ok, questions_params}
    end
  end

  @spec log_error_bad_changeset(Ecto.Changeset.t(), any()) :: :ok
  defp log_error_bad_changeset(changeset, entity) do
    Logger.error("Invalid #{entity} changeset. Error: #{full_error_messages(changeset)}")

    Logger.error("Changeset: #{inspect(changeset, pretty: true)}")
  end

  @spec process_question_by_question_type(map()) :: map() | {:error, String.t()}
  defp process_question_by_question_type(question) do
    question[:entity]
    |> process_question_entity_by_type(question[:type])
    |> case do
      question_map when is_map(question_map) ->
        Map.put(question, :question, question_map)

      {:error, error_message} ->
        {:error, error_message}
    end
  end

  defp process_question_entity_by_type(entity, "programming") do
    Map.merge(
      entity
      |> xpath(
        ~x"."e,
        content: ~x"./TEXT/text()" |> transform_by(&process_charlist/1),
        prepend: ~x"./SNIPPET/PREPEND/text()" |> transform_by(&process_charlist/1),
        template: ~x"./SNIPPET/TEMPLATE/text()" |> transform_by(&process_charlist/1),
        postpend: ~x"./SNIPPET/POSTPEND/text()" |> transform_by(&process_charlist/1),
        solution: ~x"./SNIPPET/SOLUTION/text()" |> transform_by(&process_charlist/1),
        llm_prompt: ~x"./LLM_GRADING_PROMPT/text()" |> transform_by(&process_charlist/1)
      ),
      entity
      |> xmap(
        public: [
          ~x"./SNIPPET/TESTCASES/PUBLIC"l,
          score: ~x"./@score"oi,
          answer: ~x"./@answer" |> transform_by(&process_charlist/1),
          program: ~x"./text()" |> transform_by(&process_charlist/1)
        ],
        opaque: [
          ~x"./SNIPPET/TESTCASES/OPAQUE"l,
          score: ~x"./@score"oi,
          answer: ~x"./@answer" |> transform_by(&process_charlist/1),
          program: ~x"./text()" |> transform_by(&process_charlist/1)
        ],
        secret: [
          ~x"./SNIPPET/TESTCASES/SECRET"l,
          score: ~x"./@score"oi,
          answer: ~x"./@answer" |> transform_by(&process_charlist/1),
          program: ~x"./text()" |> transform_by(&process_charlist/1)
        ]
      )
    )
  end

  defp process_question_entity_by_type(entity, "mcq") do
    choices =
      entity
      |> xpath(
        ~x"./CHOICE"el,
        content: ~x"./TEXT/text()" |> transform_by(&process_charlist/1),
        is_correct: ~x"./@correct"s |> transform_by(&String.to_atom/1),
        hint: ~x"./@hint"s
      )
      |> Enum.with_index()
      |> Enum.map(fn {choice, id} -> Map.put(choice, :choice_id, id) end)

    entity
    |> xpath(~x"."e, content: ~x"./TEXT/text()" |> transform_by(&process_charlist/1))
    |> Map.put(:choices, choices)
  end

  defp process_question_entity_by_type(entity, "voting") do
    question_data =
      Map.merge(
        entity
        |> xpath(
          ~x"."e,
          content: ~x"./TEXT/text()" |> transform_by(&process_charlist/1),
          prepend: ~x"./SNIPPET/PREPEND/text()" |> transform_by(&process_charlist/1),
          template: ~x"./SNIPPET/TEMPLATE/text()" |> transform_by(&process_charlist/1)
        ),
        entity
        |> xpath(
          ~x"./VOTING"e,
          contest_number: ~x"./@assessment_number"s,
          reveal_hours: ~x"./@reveal_hours"i,
          token_divider: ~x"./@token_divider"i
        )
      )

    xp_values =
      entity
      |> xpath(~x"./VOTING/XP_ARRAY/XP"el, value: ~x"./@value"i)
      |> Enum.map(& &1[:value])

    if xp_values == [], do: question_data, else: Map.merge(question_data, %{xp_values: xp_values})
  end

  defp process_question_entity_by_type(_, _) do
    {:error, "Invalid question type."}
  end

  @spec process_question_library(map(), any(), any()) :: map() | {:error, String.t()}
  defp process_question_library(question, default_library, default_grading_library) do
    library = xpath(question[:entity], ~x"./PROGRAMMINGLANGUAGE"o) || default_library

    grading_library =
      xpath(question[:entity], ~x"./GRADERPROGRAMMINGLANGUAGE"o) || default_grading_library ||
        library

    if library do
      question
      |> Map.put(:library, parse_programming_language(library))
      |> Map.put(:grading_library, parse_programming_language(grading_library))
    else
      {:error, "Missing PROGRAMMINGLANGUAGE"}
    end
  end

  @spec parse_programming_language(any()) :: map()
  defp parse_programming_language(library_entity) do
    globals =
      library_entity
      |> xpath(
        ~x"./GLOBAL"l,
        identifier: ~x"./IDENTIFIER/text()" |> transform_by(&process_charlist/1),
        value: ~x"./VALUE/text()" |> transform_by(&process_charlist/1)
      )
      |> Enum.reduce(%{}, fn %{identifier: identifier, value: value}, acc ->
        Map.put(acc, identifier, value)
      end)

    external =
      library_entity
      |> xpath(
        ~x"./EXTERNAL"o,
        name: ~x"./@name"s |> transform_by(&String.downcase/1),
        symbols: ~x"./SYMBOL/text()"sl
      )

    options_list =
      library_entity
      |> xpath(~x"./OPTION"el, key: ~x"./@key"s, value: ~x"./@value"s)

    options_map =
      options_list |> Map.new(&{&1.key, &1.value})

    library_entity
    |> xpath(
      ~x"."e,
      chapter: ~x"./@interpreter"i,
      exec_time_ms: ~x"./@exectime"oi,
      variant: ~x"./@variant"os
    )
    |> Map.put(:globals, globals)
    |> Map.put(:external, external)
    |> Map.put(:language_options, options_map)
  end

  @spec process_charlist(charlist() | nil) :: String.t() | nil

  defp process_charlist(nil) do
    nil
  end

  defp process_charlist(charlist) do
    charlist
    |> to_string()
    |> String.trim()
  end

  defp log_and_return_badrequest(error_message) do
    Logger.error(error_message)
    {:error, {:bad_request, error_message}}
  end

  defp nested_tuple_to_list(tuple) when is_tuple(tuple) do
    tuple |> Tuple.to_list() |> Enum.map(&nested_tuple_to_list/1)
  end

  defp nested_tuple_to_list(x), do: x
end
