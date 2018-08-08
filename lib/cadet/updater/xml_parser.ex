defmodule Cadet.Updater.XMLParser do
  @moduledoc """
  Parser for XML files from the cs1101s repository.
  """
  @local_name if Mix.env() != :test, do: "cs1101s", else: "test/fixtures/local_repo"
  @locations %{mission: "missions", sidequest: "quests", path: "paths", contest: "contests"}

  @type assessment_type :: :mission | :sidequest | :path | :contest

  use Cadet, [:display]

  import SweetXml

  alias Cadet.Assessments

  require Logger

  defmacrop is_non_empty_list(term) do
    quote do: is_list(unquote(term)) and unquote(term) != []
  end

  @spec parse_and_insert(:all) :: :ok | {:error, [{assessment_type(), String.t()}]}
  @spec parse_and_insert(assessment_type()) :: :ok | {:error, String.t()}

  def parse_and_insert(:all) do
    errors =
      for {key, _} <- @locations do
        {key, parse_and_insert(key)}
      end
      |> Enum.filter(fn
        {_, {:error, _}} -> true
        {_, :ok} -> false
      end)
      |> Enum.map(fn {type, {:error, reason}} -> {type, reason} end)

    if Enum.empty?(errors) do
      :ok
    else
      {:error, errors}
    end
  end

  def parse_and_insert(type) do
    with {:assessment_type, true} <- {:assessment_type, type in Map.keys(@locations)},
         {:cloned?, {:ok, root}} when is_non_empty_list(root) <- {:cloned?, File.ls(@local_name)},
         {:type, true} <- {:type, @locations[type] in root},
         {:listing, {:ok, listing}} when is_non_empty_list(listing) <-
           {:listing, @local_name |> Path.join(@locations[type]) |> File.ls()},
         {:filter, xml_files} when is_non_empty_list(xml_files) <-
           {:filter, Enum.filter(listing, &String.ends_with?(&1, ".xml"))},
         {:process, :ok} <-
           {:process, process_xml_files(Path.join(@local_name, @locations[type]), xml_files)} do
      :ok
    else
      {:assessment_type, false} -> {:error, "XML location of assessment type is not defined."}
      {:cloned?, _} -> {:error, "Local copy of repository is either missing or empty."}
      {:type, false} -> {:error, "Directory containing XML is not found."}
      {:listing, _} -> {:error, "Directory containing XML is empty."}
      {:filter, _} -> {:error, "No XML file is found."}
      {:process, :error} -> {:error, "Error processing XML files."}
    end
  end

  @spec process_xml_files(String.t(), [String.t()]) :: :ok | :error
  defp process_xml_files(path, files) do
    for file <- files do
      path
      |> Path.join(file)
      |> File.read!()
      |> parse_xml()
      |> case do
        :ok ->
          Logger.info("Imported #{file} successfully.\n")
          :ok

        :error ->
          Logger.error("Failed to import #{file}.\n")
          :error
      end
    end
    |> Enum.any?(&(&1 == :error))
    |> case do
      true -> :error
      false -> :ok
    end
  end

  @spec parse_xml(String.t()) :: :ok | :error
  def parse_xml(xml) do
    with {:ok, assessment_params} <- process_assessment(xml),
         {:ok, questions_params} <- process_questions(xml),
         {:ok, %{assessment: assessment}} <-
           Assessments.insert_or_update_assessments_and_questions(
             assessment_params,
             questions_params
           ) do
      Logger.info(
        "Created/updated assessment with id: #{assessment.id}, with #{length(questions_params)} questions."
      )

      :ok
    else
      :error ->
        :error

      {:error, stage, changeset, _} when is_atom(stage) ->
        log_error_bad_changeset(changeset, stage)
        :error
    end
  catch
    # the :erlsom library used by SweetXml will exit if XML is invalid
    :exit, _ ->
      :error
  end

  @spec process_assessment(String.t()) :: {:ok, map()} | :error
  defp process_assessment(xml) do
    assessment_params =
      xml
      |> xpath(
        ~x"//TASK"e,
        type: ~x"./@kind"s,
        title: ~x"./@title"s,
        open_at: ~x"./@startdate"s |> transform_by(&Timex.parse!(&1, "{ISO:Extended}")),
        close_at: ~x"./@duedate"s |> transform_by(&Timex.parse!(&1, "{ISO:Extended}")),
        number: ~x"./@number"s,
        story: ~x"./@story"s,
        cover_picture: ~x"./@coverimage"s,
        reading: ~x"//READING/text()" |> transform_by(&process_charlist/1),
        summary_short: ~x"//WEBSUMMARY/text()" |> transform_by(&process_charlist/1),
        summary_long: ~x"./TEXT/text()" |> transform_by(&process_charlist/1)
      )
      |> Map.put(:is_published, true)

    if verify_has_time_offset(assessment_params) do
      {:ok, assessment_params}
    else
      Logger.error("Time does not have offset specified.")
      :error
    end
  rescue
    e in Timex.Parse.ParseError ->
      Logger.error("Time does not conform to ISO8601 DateTime: #{e.message}")
      :error

    # This error is raised by xpath/3 when TASK does not exist (hence is equal to nil)
    Protocol.UndefinedError ->
      Logger.error("Missing TASK")
      :error
  end

  @spec verify_has_time_offset(%{
          open_at: DateTime.t() | NaiveDateTime.t(),
          close_at: DateTime.t() | NaiveDateTime.t()
        }) :: boolean()
  defp verify_has_time_offset(%{open_at: open_at, close_at: close_at}) do
    # Timex.parse!/2 returns NaiveDateTime when offset is not specified, or DateTime otherwise.
    open_at.__struct__ != NaiveDateTime and close_at.__struct__ != NaiveDateTime
  end

  @spec process_questions(String.t()) :: {:ok, [map()]} | :error
  defp process_questions(xml) do
    default_library = xpath(xml, ~x"//TASK/DEPLOYMENT"e)

    questions_params =
      xml
      |> xpath(
        ~x"//PROBLEMS/PROBLEM"el,
        type: ~x"./@type"o |> transform_by(&process_charlist/1),
        max_grade: ~x"./@maxgrade"oi,
        entity: ~x"."
      )
      |> Enum.map(fn param ->
        with {:no_missing_attr?, true} <-
               {:no_missing_attr?, not is_nil(param[:type]) and not is_nil(param[:max_grade])},
             question when is_map(question) <- process_question_by_question_type(param),
             question when is_map(question) <-
               process_question_library(question, default_library),
             question when is_map(question) <- Map.delete(question, :entity) do
          question
        else
          {:no_missing_attr?, false} ->
            Logger.error("Missing attribute(s) on PROBLEM")
            :error

          :error ->
            :error
        end
      end)

    if Enum.any?(questions_params, &(&1 == :error)) do
      :error
    else
      {:ok, questions_params}
    end
  end

  @spec log_error_bad_changeset(Ecto.Changeset.t(), any()) :: :ok
  defp log_error_bad_changeset(changeset, entity) do
    Logger.error("Invalid #{entity} changeset. Error: #{full_error_messages(changeset.errors)}")

    Logger.error("Changeset: #{inspect(changeset, pretty: true)}")
  end

  @spec process_question_by_question_type(map()) :: map() | :error
  defp process_question_by_question_type(question) do
    question[:entity]
    |> process_question_entity_by_type(question[:type])
    |> case do
      question_map when is_map(question_map) ->
        Map.put(question, :question, question_map)

      :error ->
        :error
    end
  end

  defp process_question_entity_by_type(entity, "programming") do
    entity
    |> xpath(
      ~x"."e,
      content: ~x"./TEXT/text()" |> transform_by(&process_charlist/1),
      solution_template: ~x"./SNIPPET/TEMPLATE/text()" |> transform_by(&process_charlist/1),
      solution: ~x"./SNIPPET/SOLUTION/text()" |> transform_by(&process_charlist/1),
      autograder:
        ~x"./SNIPPET/GRADER/text()"l
        |> transform_by(&Enum.map(&1, fn charlist -> process_charlist(charlist) end))
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

  defp process_question_entity_by_type(_, _) do
    Logger.error("Invalid question type.")
    :error
  end

  @spec process_question_library(map(), any()) :: map() | :error
  defp process_question_library(question, default_library) do
    library = xpath(question[:entity], ~x"./DEPLOYMENT"o) || default_library
    grading_library = xpath(question[:entity], ~x"./GRADERDEPLOYMENT"o) || library

    if library do
      question
      |> Map.put(:library, process_question_library(library))
      |> Map.put(:grading_library, process_question_library(grading_library))
    else
      Logger.error("Missing DEPLOYMENT")
      :error
    end
  end

  @spec process_question_library(any()) :: map()
  defp process_question_library(library_entity) do
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

    library_entity
    |> xpath(
      ~x"."e,
      chapter: ~x"./@interpreter"i
    )
    |> Map.put(:globals, globals)
    |> Map.put(:external, external)
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
end
