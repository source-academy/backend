defmodule Cadet.Updater.XMLParser do
  @moduledoc """
  Parser for XML files from the cs1101s repository.
  """
  @local_name if Mix.env() != :test, do: "cs1101s", else: "test/local_repo"
  @locations %{mission: "missions", sidequest: "quests", path: "paths", contest: "contests"}


  import SweetXml

  alias Cadet.Assessments.Assessment

  defmacrop is_non_empty_list(term) do
    quote do: is_list(unquote(term)) and unquote(term) != []
  end

  @spec parse_and_insert(:mission | :sidequest | :path | :contest) ::
          {:ok, nil} | {:error, String.t()}
  def parse_and_insert(type) do
    with {:assessment_type, true} <- {:assessment_type, type in Map.keys(@locations)},
         {:cloned?, {:ok, root}} when is_non_empty_list(root) <- {:cloned?, File.ls(@local_name)},
         {:type, true} <- {:type, @locations[type] in root},
         {:listing, {:ok, listing}} when is_non_empty_list(listing) <-
           {:listing, @local_name |> Path.join(@locations[type]) |> File.ls()},
         {:filter, xml_files} when is_non_empty_list(xml_files) <-
           {:filter, Enum.filter(listing, &String.ends_with?(&1, ".xml"))} do
      process_xml_files(Path.join(@local_name, @locations[type]), xml_files)
      {:ok, nil}
    else
      {:assessment_type, false} -> {:error, "XML location of assessment type is not defined."}
      {:cloned?, {:error, _}} -> {:error, "Local copy of repository is either missing or empty."}
      {:type, false} -> {:error, "Directory containing XML is not found."}
      {:listing, {:error, _}} -> {:error, "Directory containing XML is empty."}
      {:filter, _} -> {:error, "No XML file is found."}
    end
  end

  def process_xml_files(path, files) do
    for file <- files do
      assessment =
        path
        |> Path.join(file)
        |> File.read!()
        |> process()

      IO.puts(inspect(assessment, pretty: true))
    end
  end

  # TODO: change to `defp`
  @spec process(String.t()) :: %Assessment{}
  def process(xml) do
    assessment_changeset =
      xml
      |> xpath(
        ~x"//TASK"e,
        type: ~x"./@kind"s,
        title: ~x"./@title"s,
        open_at: ~x"./@startdate"s |> transform_by(&Timex.parse!(&1, "{ISO:Extended}")),
        close_at: ~x"./@duedate"s |> transform_by(&Timex.parse!(&1, "{ISO:Extended}")),
        number: ~x"./@number"s,
        story: ~x"./@story"s,
        reading: ~x"//READING/text()" |> transform_by(&process_charlist/1),
        summary_short: ~x"//WEBSUMMARY/text()" |> transform_by(&process_charlist/1),
        summary_long: ~x"./TEXT/text()" |> transform_by(&process_charlist/1)
      )
      |> Map.put(:is_published, true)

    Assessment.changeset(%Assessment{}, assessment_changeset)
  end

  def process_question(xml, assessment_id) do
    default_library = xpath(xml, ~x"//TASK/DEPLOYMENT"e)

    question_changeset =
      xml
      |> xpath(
        ~x"//PROBLEMS/PROBLEM"el,
        type: ~x"./@type"s,
        max_grade: ~x"./@maxgrade"i,
        entity: ~x"."
      )
      |> Enum.map(&process_question_by_question_type/1)
      |> Enum.map(&process_question_library(&1, default_library))
      |> Enum.map(&Map.delete(&1, :entity))

    question_changeset
  end

  defp process_question_by_question_type(question) do
    entity = question[:entity]

    question_map =
      case question[:type] do
        "programming" ->
          entity
          |> xpath(
            ~x"."e,
            content: ~x"./TEXT/text()" |> transform_by(&process_charlist/1),
            solution_template: ~x"./SNIPPET/TEMPLATE/text()" |> transform_by(&process_charlist/1),
            solution: ~x"./SNIPPET/SOLUTION/text()" |> transform_by(&process_charlist/1),
            grader: ~x"./SNIPPET/GRADER/text()" |> transform_by(&process_charlist/1)
          )

        "mcq" ->
          choices =
            entity
            |> xpath(
              ~x"./CHOICE"el,
              content: ~x"./TEXT/text()" |> transform_by(&process_charlist/1),
              is_correct: ~x"./@correct"s |> transform_by(&String.to_atom/1)
            )
            |> Enum.with_index()
            |> Enum.map(fn {choice, id} -> Map.put(choice, :choice_id, id) end)

          entity
          |> xpath(~x"."e, content: ~x"./TEXT/text()" |> transform_by(&process_charlist/1))
          |> Map.put(:choices, choices)
      end

    Map.put(question, :question, question_map)
  end

  defp process_question_library(question, default_library) do
    library = xpath(question[:entity], ~x"./DEPLOYMENT"o) || default_library

    globals =
      library
      |> xpath(
        ~x"./GLOBAL"l,
        identifier: ~x"./IDENTIFIER/text()" |> transform_by(&process_charlist/1),
        value: ~x"./VALUE/text()" |> transform_by(&process_charlist/1)
      )

    library =
      library
      |> xpath(
        ~x"."e,
        chapter: ~x"./@interpreter"i
      )
      |> Map.put(:globals, globals)

    IO.puts(inspect(library))

    Map.put(question, :library, library)
  end

  # TODO: delete this
  def xml do
    @xml
  end

  @spec process_charlist(charlist()) :: String.t()
  defp process_charlist(charlist) do
    charlist
    |> to_string()
    |> String.trim()
  end
end
