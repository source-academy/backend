defmodule Cadet.Updater.XMLParser do
  @moduledoc """
  Parser for XML files from the cs1101s repository.
  """
  @local_name if Mix.env() != :test, do: "cs1101s", else: "test/local_repo"
  @locations %{mission: "missions", sidequest: "quests", path: "paths", contest: "contests"}

  @xml """
  <?xml version="1.0"?>
  <CONTENT xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xlink="http://128.199.210.247">

  <!-- ***********************************************************************
  **** MISSION #M99
  ************************************************************************ -->
  <TASK kind="mission" number="M99" startdate="2018-08-24T23:59+08" duedate="2018-09-20T23:59+08" title="Simple Stuff" story="mission-99">

  <READING>Textbook Sections 1.1.1 to 1.1.2</READING>
  <WEBSUMMARY>
  Welcome to your 99th mission!
  </WEBSUMMARY>
  <TEXT>
  Welcome to this assessment! This is the *briefing*.

  This mission consists of **four tasks**.

  1. A simple PROBLEM that uses the default DEPLOYMENT and GRADERDEPLOYMENT
   for its GRADER programs (source 1).
  2. A sorting PROBLEM that uses it's own DEPLOYMENT AND GRADERDEPLOYMENT.
   Here, GLOBALs and EXTERNAL are used to pre-define lists for the students
   as well as the grader to test the functions with.
  3. An MCQ question.
  4. A question which makes use of an EXTERNAL library, TWO_DIM_RUNES. The
   functions from the library TWO_DIM_RUNES are exposed to the source
   interpreter's global namespace according to what is specified in the
   SYMBOL elements.
  </TEXT>

  <PROBLEMS>
    <PROBLEM maxgrade="2" type="programming">
      <TEXT>
  Your first task is to define a function `sum` that adds two numbers together.
      </TEXT>
        <SNIPPET>
          <TEMPLATE>
  const sum = () => 0; // Replace with your solution

  // test your program!
  sum(3, 5); // returns 8
          </TEMPLATE>
          <SOLUTION>
  // [Marking Scheme]
  // You may subtract 1 from grade if the student does not use arrow functions.
          </SOLUTION>
          <GRADER>
  function neiYa7eil5() {
  const test1 = sum(10, 10) === 20;
  const test2 = sum(0, 0) === 0;
  const test3 = sum(99, 1) === 100;
  return test1 &amp;&amp; test2 &amp;&amp; test3 ? 1 : 0;
  }

  neiYa7eil5();
          </GRADER>
          <GRADER>
  function neiYa7eil5() {
  const test1 = sum(-10, 10) === 0;
  const test2 = sum(-1, -1) === -2;
  const test3 = sum(-99, 1) === 98;
  return test1 &amp;&amp; test2 &amp;&amp; test3 ? 1 : 0;
  }

  neiYa7eil5();
          </GRADER>
        </SNIPPET>
      </PROBLEM>

      <PROBLEM maxgrade="5" type="programming">
        <TEXT>
  Now, sort a list by any means. You are provided a list of numbers to test
  your sort function out with.
        </TEXT>
        <SNIPPET>
          <TEMPLATE>
  function sort() {
  // your solution here
  }

  // test your program!
  sort(numbers); // should be [1, 3, 5, 7]
          </TEMPLATE>
          <GRADER>
  function neiYa7eil5() {
  return equal(list(1, 3, 5, 7), sort(numbers)) ? 1 : 0;
  }

  neiYa7eil5();
          </GRADER>
          <GRADER>
  function neiYa7eil5() {
  return equal(
    list(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15),
    sort(bigNumbers)
  ) ? 4 : 0;
  }

  neiYa7eil5();
          </GRADER>
        </SNIPPET>
        <DEPLOYMENT interpreter="2">
          <EXTERNAL name="NONE">
            <SYMBOL>numbers</SYMBOL>
          </EXTERNAL>
          <GLOBAL>
            <IDENTIFIER>numbers</IDENTIFIER>
            <!-- The source stdlib is available -->
            <VALUE>list(5, 1, 7, 3)</VALUE>
          </GLOBAL>
        </DEPLOYMENT>
        <GRADERDEPLOYMENT interpreter="2">
          <EXTERNAL name="NONE">
            <SYMBOL>numbers</SYMBOL>
            <SYMBOL>bigNumbers</SYMBOL>
          </EXTERNAL>
          <GLOBAL>
            <IDENTIFIER>numbers</IDENTIFIER>
            <!-- The source stdlib is available -->
            <VALUE>list(5, 1, 7, 3)</VALUE>
            <IDENTIFIER>bigNumbers</IDENTIFIER>
            <VALUE>list(15, 14, 13, 12, 11, 10, 1, 2, 3, 4, 5, 9, 8, 7, 6)</VALUE>
          </GLOBAL>
        </GRADERDEPLOYMENT>
      </PROBLEM>

      <PROBLEM maxgrade="1" type="mcq">
        <TEXT>
  What is the air-speed velocity of an unladen swallow?
        </TEXT>
        <CHOICE correct="false"><TEXT>5 meters per second</TEXT></CHOICE>
        <CHOICE correct="false"><TEXT>8 meters per second</TEXT></CHOICE>
        <CHOICE correct="true"><TEXT>11 meters per second</TEXT></CHOICE>
        <CHOICE correct="false"><TEXT>24 meters per second</TEXT></CHOICE>
      </PROBLEM>

      <PROBLEM maxgrade="0" type="programming">
        <TEXT>
  You'll use runes in your next mission. Why don't you give it a try?
        </TEXT>
        <SNIPPET>
          <TEMPLATE>
  // shows the rune heart_bb
  show(heart_bb);
          </TEMPLATE>
        </SNIPPET>
        <DEPLOYMENT interpreter="1">
          <EXTERNAL name="TWO_DIM_RUNES">
            <SYMBOL>show</SYMBOL>
            <SYMBOL>heart_bb</SYMBOL>
          </EXTERNAL>
        </DEPLOYMENT>
      </PROBLEM>

    </PROBLEMS>

    <TEXT>
  ## Submission

  Make sure that everything for your programs to work is on the left hand side
  and **not** in the REPL on the right! This is because only that program is
  used to assess your solution.

  This TEXT will not be shown in cadet, but may be useful in the generated pdf.
    </TEXT>

    <DEPLOYMENT interpreter="1">
    </DEPLOYMENT>

    <GRADERDEPLOYMENT interpreter="1">
    </GRADERDEPLOYMENT>

  </TASK>
  </CONTENT>
  """

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
