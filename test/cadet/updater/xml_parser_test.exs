defmodule Cadet.Updater.XMLParserTest do
  alias Cadet.Assessments.{Assessment, AssessmentType, Question}
  alias Cadet.Test.XMLGenerator
  alias Cadet.Updater.XMLParser

  use Cadet.DataCase

  import Cadet.Factory
  import ExUnit.CaptureLog

  @local_name "test/fixtures/local_repo"

  # @locations %{mission: "missions", sidequest: "quests", path: "paths", contest: "contests"}

  setup do
    File.rm_rf!(@local_name)

    on_exit(fn ->
      File.rm_rf!(@local_name)
    end)

    assessments =
      Enum.map(
        AssessmentType.__enum_map__(),
        &build(:assessment, type: &1, is_published: true)
      )

    assessments_with_type = Enum.into(assessments, %{}, &{&1.type, &1})

    questions = build_list(5, :question, assessment: nil)

    %{
      assessments: assessments,
      questions: questions,
      assessments_with_type: assessments_with_type
    }
  end

  describe "Pure XML Parser" do
    test "XML Parser happy path", %{assessments: assessments, questions: questions} do
      for assessment <- assessments do
        xml = XMLGenerator.generate_xml_for(assessment, questions)

        assert XMLParser.parse_xml(xml) == :ok

        number = assessment.number

        assessment_db =
          Assessment
          |> where(number: ^number)
          |> Repo.one()

        open_at =
          Timex.now()
          |> Timex.beginning_of_day()
          |> Timex.shift(days: 3)
          |> Timex.shift(hours: 4)

        close_at = Timex.shift(open_at, days: 7)

        expected_assesment =
          assessment
          |> Map.put(:open_at, open_at)
          |> Map.put(:close_at, close_at)
          |> Map.put(:is_published, false)

        assert_map_keys(
          Map.from_struct(expected_assesment),
          Map.from_struct(assessment_db),
          ~w(title is_published type summary_short summary_long open_at close_at)a ++
            ~w(number story reading password)a
        )

        assessment_id = assessment_db.id

        questions_db =
          Question
          |> where(assessment_id: ^assessment_id)
          |> order_by(asc: :display_order)
          |> Repo.all()

        for {question, question_db} <- Enum.zip(questions, questions_db) do
          assert_map_keys(
            Map.from_struct(question_db),
            Map.from_struct(question),
            ~w(question type library)a
          )
        end
      end
    end

    test "happy path existing still closed assessment", %{
      assessments: assessments,
      questions: questions
    } do
      for assessment <- assessments do
        still_closed_assessment =
          Map.from_struct(%{
            assessment
            | open_at: Timex.shift(Timex.now(), days: 2),
              close_at: Timex.shift(Timex.now(), days: 6)
          })

        %Assessment{}
        |> Assessment.changeset(still_closed_assessment)
        |> Repo.insert!()

        xml = XMLGenerator.generate_xml_for(assessment, questions)

        assert XMLParser.parse_xml(xml) == :ok
      end
    end

    test "PROBLEM with missing type", %{assessments: assessments, questions: questions} do
      for assessment <- assessments do
        xml =
          XMLGenerator.generate_xml_for(assessment, questions, problem_permit_keys: ~w(maxgrade)a)

        assert capture_log(fn ->
                 assert(
                   XMLParser.parse_xml(xml) ==
                     {:error, {:bad_request, "Missing attribute(s) on PROBLEM"}}
                 )
               end) =~
                 "Missing attribute(s) on PROBLEM"
      end
    end

    test "PROBLEM with missing maxgrade", %{assessments: assessments, questions: questions} do
      for assessment <- assessments do
        xml = XMLGenerator.generate_xml_for(assessment, questions, problem_permit_keys: ~w(type)a)

        assert capture_log(fn ->
                 assert(
                   XMLParser.parse_xml(xml) ==
                     {:error, {:bad_request, "Missing attribute(s) on PROBLEM"}}
                 )
               end) =~
                 "Missing attribute(s) on PROBLEM"
      end
    end

    test "Invalid question type", %{assessments: assessments, questions: questions} do
      for assessment <- assessments do
        xml = XMLGenerator.generate_xml_for(assessment, questions, override_type: "anu")

        assert capture_log(fn ->
                 assert(
                   XMLParser.parse_xml(xml) == {:error, {:bad_request, "Invalid question type."}}
                 )
               end) =~
                 "Invalid question type."
      end
    end

    test "Invalid question changeset", %{assessments: assessments, questions: questions} do
      for assessment <- assessments do
        questions_without_content =
          Enum.map(questions, &%{&1 | question: %{&1.question | content: ""}})

        xml = XMLGenerator.generate_xml_for(assessment, questions_without_content)

        # the error message can be quite convoluted
        assert capture_log(fn ->
                 assert({:error, {:bad_request, _error_message}} = XMLParser.parse_xml(xml))
               end) =~
                 ~r/Invalid \b.*\b changeset\./
      end
    end

    test "missing DEPLOYMENT", %{assessments: assessments, questions: questions} do
      for assessment <- assessments do
        xml = XMLGenerator.generate_xml_for(assessment, questions, no_deployment: true)

        assert capture_log(fn ->
                 assert(
                   XMLParser.parse_xml(xml) == {:error, {:bad_request, "Missing DEPLOYMENT"}}
                 )
               end) =~
                 "Missing DEPLOYMENT"
      end
    end

    test "existing already open assessment", %{assessments: assessments, questions: questions} do
      for assessment <- assessments do
        already_open_assessment =
          Map.from_struct(%{
            assessment
            | open_at: Timex.shift(Timex.now(), days: -2),
              close_at: Timex.shift(Timex.now(), days: 2)
          })

        %Assessment{}
        |> Assessment.changeset(already_open_assessment)
        |> Repo.insert!()

        xml = XMLGenerator.generate_xml_for(assessment, questions)

        assert capture_log(fn ->
                 assert XMLParser.parse_xml(xml) == {:ok, "Assessment already open, ignoring..."}
               end) =~
                 "Assessment already open, ignoring..."
      end
    end
  end

  describe "XML file processing" do
    test "happy path by category", %{
      assessments_with_type: assessments_with_type,
      questions: questions
    } do
      for {type, assessment} <- assessments_with_type do
        type_string = Atom.to_string(type)
        xml = XMLGenerator.generate_xml_for(assessment, questions)

        path = Path.join(@local_name, type_string)

        file_name = String.capitalize(type_string) <> "-#{assessment.number}.xml"

        location = Path.join(path, file_name)

        File.mkdir_p!(path)
        File.write!(location, xml)
      end

      assert XMLParser.parse_and_insert(@local_name) == :ok
    end

    test "happy path process all", %{
      assessments_with_type: assessments_with_type,
      questions: questions
    } do
      for {type, assessment} <- assessments_with_type do
        xml = XMLGenerator.generate_xml_for(assessment, questions)

        path = Path.join(@local_name, Atom.to_string(type))

        file_name =
          (type |> Atom.to_string() |> String.capitalize()) <> "-#{assessment.number}.xml"

        location = Path.join(path, file_name)

        File.mkdir_p!(path)
        File.write!(location, xml)
      end

      assert XMLParser.parse_and_insert(@local_name) == :ok
    end

    test "repository not cloned" do
      for type <- AssessmentType.__enum_map__() do
        location = Atom.to_string(type)

        assert XMLParser.parse_and_insert(location) ==
                 {:error, "Local copy of repository is either missing or empty."}
      end
    end

    test "no xml file is found" do
      for type <- AssessmentType.__enum_map__() do
        location = Atom.to_string(type)

        path = Path.join(@local_name, location)

        File.mkdir_p!(path)

        path |> Path.join("Never-gonna-give-you-up.mp3") |> File.touch!()

        assert XMLParser.parse_and_insert(path) == :ok
      end
    end

    test "empty xml file" do
      for type <- AssessmentType.__enum_map__() do
        location = Atom.to_string(type)

        path = Path.join(@local_name, location)

        File.mkdir_p!(path)

        path |> Path.join("lambda.xml") |> File.touch!()

        assert capture_log(fn ->
                 assert XMLParser.parse_and_insert(path) ==
                          {:error, "Error processing XML files."}
               end) =~ ":expected_element_start_tag"
      end
    end

    test "valid xml file but invalid assessment xml" do
      for type <- AssessmentType.__enum_map__() do
        location = Atom.to_string(type)
        path = Path.join(@local_name, location)

        File.mkdir_p!(path)

        location = Path.join(path, "best-markup-language.xml")

        File.write!(location, """
        <html>
        <head><title>Best markup language!</title></head>
        <body>
        <blink>Sadly this usually won't work in newer browsers</blink>
        </body>
        </html>
        """)

        assert capture_log(fn ->
                 XMLParser.parse_and_insert(path) == {:error, {:bad_request, "Missing TASK"}}
               end) =~ "Missing TASK"
      end
    end

    test "hidden folders are ignored" do
      for type <- AssessmentType.__enum_map__() do
        location = Atom.to_string(type)

        path = Path.join([@local_name, ".hidden", location])

        File.mkdir_p!(path)

        path |> Path.join("lambda.xml") |> File.touch!()

        assert XMLParser.parse_and_insert(@local_name) == :ok
      end
    end

    test "recursive folders and explored and parsed" do
      for type <- AssessmentType.__enum_map__() do
        location = Atom.to_string(type)

        path = Path.join([@local_name, "recursive", location])

        File.mkdir_p!(path)

        path |> Path.join("lambda.xml") |> File.touch!()

        assert capture_log(fn ->
                 assert XMLParser.parse_and_insert(@local_name) == :ok
               end) =~ ":expected_element_start_tag"
      end
    end
  end

  defp assert_list(list1, list2) when is_list(list1) and is_list(list2) do
    assert length(list1) == length(list2)

    for {member1, member2} <- Enum.zip(list1, list2) do
      case member1 do
        map when is_map(map) ->
          assert_map_keys(
            convert_map_keys_to_string(member1),
            convert_map_keys_to_string(member2),
            member1 |> Map.keys() |> Enum.map(&stringify/1)
          )

        _ ->
          assert(member1 == member2, "list1: #{inspect(list1)}, list2: #{inspect(list2)}")
      end
    end
  end

  defp stringify(atom) when is_atom(atom), do: Atom.to_string(atom)
  defp stringify(string) when is_binary(string), do: string

  defp assert_map_keys(map1, map2, keys) when is_map(map1) and is_map(map2) do
    for key <- keys do
      assert_error_message =
        "key: #{inspect(key)}, map1[key]: #{inspect(map1[key])}, map2[key]: #{inspect(map2[key])}"

      case map1[key] do
        %DateTime{} ->
          assert(Timex.equal?(map1[key], map2[key]), assert_error_message)

        %{} ->
          assert_map_keys(
            convert_map_keys_to_string(map1[key]),
            convert_map_keys_to_string(map2[key]),
            Map.keys(map1[key])
          )

        list when is_list(list) ->
          assert_list(map1[key], map2[key])

        _ ->
          assert(map1[key] == map2[key], assert_error_message)
      end
    end
  end

  defp convert_map_keys_to_string(struct = %{__struct__: _}) do
    struct |> Map.from_struct() |> convert_map_keys_to_string()
  end

  defp convert_map_keys_to_string(map) when is_map(map) do
    map
    |> Enum.into(%{}, fn
      {k, v} when is_atom(k) -> {Atom.to_string(k), v}
      {k, v} -> {k, v}
    end)
    |> Enum.into(%{}, fn
      {k, v} when is_map(v) -> {k, convert_map_keys_to_string(v)}
      {k, v} -> {k, v}
    end)
  end
end
