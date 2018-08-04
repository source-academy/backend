defmodule Cadet.Updater.XMLParserTest do
  alias Cadet.Assessments.{Assessment, AssessmentType, Question}
  alias Cadet.Test.XMLGenerator
  alias Cadet.Updater.XMLParser

  use Cadet.DataCase

  import Cadet.Factory
  import ExUnit.CaptureLog

  setup do
    assessments =
      Enum.into(
        AssessmentType.__enum_map__(),
        %{},
        &{&1, build(:assessment, type: &1, is_published: true)}
      )

    questions = build_list(5, :question, assessment: nil)
    %{assessments: assessments, questions: questions}
  end

  test "XML Parser happy path", %{assessments: assessments, questions: questions} do
    for {_type, assessment} <- assessments do
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

    for {_type, assessment} <- assessments,
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
    for {_type, assessment} <- assessments do
      xml =
        XMLGenerator.generate_xml_for(assessment, questions, problem_permit_keys: ~w(maxgrade)a)

      assert capture_log(fn -> assert(XMLParser.parse_xml(xml) == :error) end) =~
               "Missing attribute(s) on PROBLEM"
    end
  end

  test "PROBLEM with missing maxgrade", %{assessments: assessments, questions: questions} do
    for {_type, assessment} <- assessments do
      xml = XMLGenerator.generate_xml_for(assessment, questions, problem_permit_keys: ~w(type)a)

      assert capture_log(fn -> assert(XMLParser.parse_xml(xml) == :error) end) =~
               "Missing attribute(s) on PROBLEM"
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
    Enum.into(map, %{}, fn
      {k, v} when is_atom(k) and is_map(v) -> {Atom.to_string(k), convert_map_keys_to_string(v)}
      {k, v} when is_atom(k) -> {Atom.to_string(k), v}
      {k, v} when is_map(v) -> {k, convert_map_keys_to_string(v)}
      {k, v} -> {k, v}
    end)
  end
end
