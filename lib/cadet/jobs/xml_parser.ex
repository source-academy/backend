defmodule Cadet.Updater.XMLParser do
  @moduledoc """
  Parser for XML files from the cs1101s repository.
  """
  @local_name if Mix.env() != :test, do: "cs1101s", else: "test/fixtures/local_repo"

  use Cadet, [:display]

  import SweetXml

  alias Cadet.Assessments

  require Logger

  defmacrop is_non_empty_list(term) do
    quote do: is_list(unquote(term)) and unquote(term) != []
  end

  @spec parse_and_insert(String.t()) :: :ok | {:error, String.t()}

  def parse_and_insert(root \\ @local_name) do
    Logger.info("Exploring folder \"#{root}\"")

    with {:cloned?, true} <- {:cloned?, File.exists?(root)},
         {:listing, {:ok, listing}} when is_non_empty_list(listing) <- {:listing, File.ls(root)},
         {:listing_folders, folders} <-
           {:listing_folders, Enum.reject(listing, &String.starts_with?(&1, "."))},
         {:join_path, folders} <- {:join_path, Enum.map(folders, &Path.join(root, &1))},
         {:filter_folders, folders} <- {:filter_folders, Enum.filter(folders, &File.dir?(&1))},
         {:process_folders, _} <-
           {:process_folders, Enum.map(folders, &parse_and_insert(&1))},
         {:filter, xml_files} when is_non_empty_list(xml_files) <-
           {:filter, Enum.filter(listing, &String.ends_with?(&1, ".xml"))},
         {:process, :ok} <-
           {:process, process_xml_files(root, xml_files)} do
      :ok
    else
      {:cloned?, false} ->
        {:error, "Local copy of repository is either missing or empty."}

      {:listing, _} ->
        Logger.info("Directory empty #{root}.")
        :ok

      {:filter, _} ->
        Logger.info("No XML file is found for folder #{root}.")
        :ok

      {:process, :error} ->
        {:error, "Error processing XML files."}
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

        {:error, {_status, error_message}} ->
          error_message = "Failed to import #{file}: #{error_message}\n"
          Logger.error(error_message)
          Sentry.capture_message(error_message)
          :error
      end
    end
    |> Enum.any?(&(&1 == :error))
    |> case do
      true -> :error
      false -> :ok
    end
  end

  @spec parse_xml(String.t(), boolean()) ::
          :ok | {:ok, String.t()} | {:error, {atom(), String.t()}}
  def parse_xml(xml, force_update \\ false) do
    with {:ok, assessment_params} <- process_assessment(xml),
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
      {:error, stage, %{errors: [assessment: {"is already open", []}]}, _} when is_atom(stage) ->
        Logger.warn("Assessment already open, ignoring...")
        {:ok, "Assessment already open, ignoring..."}

      {:error, error_message} ->
        log_and_return_badrequest(error_message)

      {:error, stage, changeset, _} when is_atom(stage) ->
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

  @spec process_assessment(String.t()) :: {:ok, map()} | {:error, String.t()}
  defp process_assessment(xml) do
    open_at =
      Timex.now()
      |> Timex.beginning_of_day()
      |> Timex.shift(days: 3)
      |> Timex.shift(hours: 4)

    close_at = Timex.shift(open_at, days: 7)

    assessment_params =
      xml
      |> xpath(
        ~x"//TASK"e,
        access: ~x"./@access"s |> transform_by(&process_access/1),
        type: ~x"./@kind"s |> transform_by(&change_quest_to_sidequest/1),
        title: ~x"./@title"s,
        number: ~x"./@number"s,
        story: ~x"./@story"s,
        cover_picture: ~x"./@coverimage"s,
        reading: ~x"//READING/text()" |> transform_by(&process_charlist/1),
        summary_short: ~x"//WEBSUMMARY/text()" |> transform_by(&process_charlist/1),
        summary_long: ~x"./TEXT/text()" |> transform_by(&process_charlist/1),
        password: ~x"//PASSWORD/text()"so |> transform_by(&process_charlist/1)
      )
      |> Map.put(:is_published, false)
      |> Map.put(:open_at, open_at)
      |> Map.put(:close_at, close_at)

    if assessment_params.access === "public" do
      Map.put(assessment_params, :password, nil)
    end

    if assessment_params.access === "private" and assessment_params.password === nil do
      Map.put(assessment_params, :password, "")
    end

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

  @spec change_quest_to_sidequest(String.t()) :: String.t()
  defp change_quest_to_sidequest("quest") do
    "sidequest"
  end

  defp change_quest_to_sidequest(type) when is_binary(type) do
    type
  end

  @spec process_questions(String.t()) :: {:ok, [map()]} | {:error, String.t()}
  defp process_questions(xml) do
    default_library = xpath(xml, ~x"//TASK/DEPLOYMENT"e)
    default_grading_library = xpath(xml, ~x"//TASK/GRADERDEPLOYMENT"e)

    questions_params =
      xml
      |> xpath(
        ~x"//PROBLEMS/PROBLEM"el,
        type: ~x"./@type"o |> transform_by(&process_charlist/1),
        max_grade: ~x"./@maxgrade"oi,
        max_xp: ~x"./@maxxp"oi,
        entity: ~x"."
      )
      |> Enum.map(fn param ->
        with {:no_missing_attr?, true} <-
               {:no_missing_attr?, not is_nil(param[:type]) and not is_nil(param[:max_grade])},
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
        solution: ~x"./SNIPPET/SOLUTION/text()" |> transform_by(&process_charlist/1)
      ),
      entity
      |> xmap(
        public: [
          ~x"./SNIPPET/TESTCASES/PUBLIC"l,
          score: ~x"./@score"oi,
          answer: ~x"./@answer" |> transform_by(&process_charlist/1),
          program: ~x"./text()" |> transform_by(&process_charlist/1)
        ],
        private: [
          ~x"./SNIPPET/TESTCASES/PRIVATE"l,
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

  defp process_question_entity_by_type(_, _) do
    {:error, "Invalid question type."}
  end

  @spec process_question_library(map(), any(), any()) :: map() | {:error, String.t()}
  defp process_question_library(question, default_library, default_grading_library) do
    library = xpath(question[:entity], ~x"./DEPLOYMENT"o) || default_library

    grading_library =
      xpath(question[:entity], ~x"./GRADERDEPLOYMENT"o) || default_grading_library || library

    if library do
      question
      |> Map.put(:library, process_question_library(library))
      |> Map.put(:grading_library, process_question_library(grading_library))
    else
      {:error, "Missing DEPLOYMENT"}
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

  defp log_and_return_badrequest(error_message) do
    Logger.error(error_message)
    {:error, {:bad_request, error_message}}
  end

  defp nested_tuple_to_list(tuple) when is_tuple(tuple) do
    tuple |> Tuple.to_list() |> Enum.map(&nested_tuple_to_list/1)
  end

  defp nested_tuple_to_list(x), do: x
end
