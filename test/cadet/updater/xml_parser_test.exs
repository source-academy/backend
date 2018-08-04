defmodule Cadet.Updater.XMLParserTest do
  alias Cadet.Assessments.{Assessment, AssessmentType, Question}
  alias Cadet.Test.XMLGenerator
  alias Cadet.Updater.XMLParser

  use Cadet.DataCase

  import Cadet.Factory

  test "XML Parser happy path" do
    for type <- AssessmentType.__enum_map__() do
      assessment = build(:assessment, type: type, is_published: true)
      questions = build_list(5, :question, assessment: nil)

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
        ~w(title is_published type summary_short summary_long open_at close_at number story reading)a
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
    |> Enum.map(fn
      {k, v} when is_atom(k) -> {Atom.to_string(k), v}
      {k, v} -> {k, v}
    end)
    |> Enum.map(fn
      {k, v} when is_map(v) -> {k, convert_map_keys_to_string(v)}
      {k, v} -> {k, v}
    end)
    |> Enum.into(%{})
  end
end
