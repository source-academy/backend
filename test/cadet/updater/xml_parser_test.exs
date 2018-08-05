defmodule Cadet.Updater.XMLParserTest do
  alias Cadet.Assessments.{Assessment, AssessmentType, Question}
  alias Cadet.Test.XMLGenerator
  alias Cadet.Updater.XMLParser

  use Cadet.DataCase

  import Cadet.Factory
  import ExUnit.CaptureLog

  @local_name "test/fixtures/local_repo"
  @locations %{mission: "missions", sidequest: "quests", path: "paths", contest: "contests"}

  setup do
    File.rm_rf!(@local_name)

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

        assert_map_keys(
          Map.from_struct(assessment),
          Map.from_struct(assessment_db),
          ~w(title is_published type summary_short summary_long open_at close_at)a ++
            ~w(number story reading)a
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

    test "dates not in ISO8601 DateTime", %{assessments: assessments, questions: questions} do
      date_strings =
        Enum.map(
          ~w({ISO:Basic} {ISOdate} {RFC822} {RFC1123} {ANSIC} {UNIX}),
          &{&1, Timex.format!(Timex.now(), &1)}
        )

      for assessment <- assessments,
          {date_format_string, date_string} <- date_strings do
        assessment_wrong_date_format = %{assessment | open_at: date_string}

        xml = XMLGenerator.generate_xml_for(assessment_wrong_date_format, questions)

        assert capture_log(fn ->
                 assert(
                   XMLParser.parse_xml(xml) == :error,
                   inspect({date_format_string, date_string}, pretty: true)
                 )
               end) =~ "Time does not conform to ISO8601 DateTime"
      end
    end

    test "PROBLEM with missing type", %{assessments: assessments, questions: questions} do
      for assessment <- assessments do
        xml =
          XMLGenerator.generate_xml_for(assessment, questions, problem_permit_keys: ~w(maxgrade)a)

        assert capture_log(fn -> assert(XMLParser.parse_xml(xml) == :error) end) =~
                 "Missing attribute(s) on PROBLEM"
      end
    end

    test "PROBLEM with missing maxgrade", %{assessments: assessments, questions: questions} do
      for assessment <- assessments do
        xml = XMLGenerator.generate_xml_for(assessment, questions, problem_permit_keys: ~w(type)a)

        assert capture_log(fn -> assert(XMLParser.parse_xml(xml) == :error) end) =~
                 "Missing attribute(s) on PROBLEM"
      end
    end

    test "Invalid question type", %{assessments: assessments, questions: questions} do
      for assessment <- assessments do
        xml = XMLGenerator.generate_xml_for(assessment, questions, override_type: "anu")

        assert capture_log(fn -> assert(XMLParser.parse_xml(xml) == :error) end) =~
                 "Invalid question type."
      end
    end

    test "Invalid question changeset", %{assessments: assessments, questions: questions} do
      for assessment <- assessments do
        questions_without_content =
          Enum.map(questions, &%{&1 | question: %{&1.question | content: ""}})

        xml = XMLGenerator.generate_xml_for(assessment, questions_without_content)

        assert capture_log(fn -> assert(XMLParser.parse_xml(xml) == :error) end) =~
                 ~r/Invalid \b.*\b changeset\./
      end
    end

    test "missing DEPLOYMENT", %{assessments: assessments, questions: questions} do
      for assessment <- assessments do
        xml = XMLGenerator.generate_xml_for(assessment, questions, no_deployment: true)

        assert capture_log(fn -> assert(XMLParser.parse_xml(xml) == :error) end) =~
                 "Missing DEPLOYMENT"
      end
    end
  end

  describe "XML file processing" do
    test "happy path", %{assessments_with_type: assessments_with_type, questions: questions} do
      for {type, assessment} <- assessments_with_type do
        xml = XMLGenerator.generate_xml_for(assessment, questions)

        path = Path.join(@local_name, @locations[type])

        file_name =
          (type |> Atom.to_string() |> String.capitalize()) <> "-#{assessment.number}.xml"

        location = Path.join(path, file_name)

        File.mkdir_p!(path)
        File.write!(location, xml)
      end

      for type <- AssessmentType.__enum_map__() do
        assert XMLParser.parse_and_insert(type) == :ok
      end
    end

    test "wrong assessment type" do
      assert XMLParser.parse_and_insert(:lambda) == {:error, "XML location of assessment type is not defined."}
    end

    test "repository not cloned" do
      for type <- AssessmentType.__enum_map__() do
        assert XMLParser.parse_and_insert(type) == {:error, "Local copy of repository is either missing or empty."}
      end
    end

    test "directory containing xml not found" do
      File.mkdir_p!(@local_name)

      @local_name |> Path.join("never-gonna-give-you-up.mp3") |> File.touch!()

      for type <- AssessmentType.__enum_map__() do
        assert XMLParser.parse_and_insert(type) == {:error, "Directory containing XML is not found."}
      end
    end

    test "directory containing xml is empty" do
      for {type, location} <- @locations do
        @local_name
        |> Path.join(location)
        |> File.mkdir_p!()

        assert XMLParser.parse_and_insert(type) == {:error, "Directory containing XML is empty."}
      end
    end

    test "no xml file is found" do
      for {type, location} <- @locations do
        path = Path.join(@local_name, location)

        File.mkdir_p!(path)

        path |> Path.join("Never-gonna-give-you-up.mp3") |> File.touch!()

        assert XMLParser.parse_and_insert(type) == {:error, "No XML file is found."}
      end
    end

    test "empty xml file" do
      for {type, location} <- @locations do
        path = Path.join(@local_name, location)

        File.mkdir_p!(path)

        path |> Path.join("lambda.xml") |> File.touch!()

        assert capture_log(fn -> assert XMLParser.parse_and_insert(type) == {:error, "Error processing XML files."} end) =~ ":expected_element_start_tag"
      end
    end
  end

  defp assert_map_keys(map1, map2, keys) do
    for key <- keys do
      assert not is_nil(map1[key])
      assert not is_nil(map2[key])

      case map1[key] do
        %DateTime{} -> Timex.equal?(map1[key], map2[key])
        %{} -> convert_map_keys_to_string(map1[key]) == convert_map_keys_to_string(map2[key])
        _ -> assert map1[key] == map2[key]
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
