defmodule Cadet.Updater.XMLParserTest do
  alias Cadet.Assessments.{Assessment, Question}
  alias Cadet.Test.XMLGenerator
  alias Cadet.Updater.XMLParser

  use Cadet.DataCase

  import Cadet.Factory
  import ExUnit.CaptureLog

  setup do
    course = insert(:course)

    assessment_configs = [
      insert(:assessment_config, %{course: course, order: 1, type: "mission"}),
      insert(:assessment_config, %{course: course, order: 2, type: "quest"}),
      insert(:assessment_config, %{
        course: course,
        order: 3,
        type: "path"
      }),
      insert(:assessment_config, %{course: course, order: 4, type: "contest"}),
      insert(:assessment_config, %{
        course: course,
        order: 5,
        type: "practical"
      })
    ]

    assessments =
      Enum.map(
        assessment_configs,
        &build(:assessment,
          course_id: course.id,
          course: course,
          config: &1,
          config_id: &1.id,
          is_published: true
        )
      )

    # contest assessment need to be added before assessment
    # containing voting questions can be added.
    contest_assessment = insert(:assessment, course: course, config: hd(assessment_configs))

    assessments_with_config = Enum.into(assessments, %{}, &{&1, &1.config})

    questions = [
      build(:programming_question),
      build(:mcq_question),
      build(:voting_question,
        question: build(:voting_question_content, contest_number: contest_assessment.number)
      )
    ]

    %{
      assessments: assessments,
      questions: questions,
      course: course,
      assessment_configs: assessment_configs,
      assessments_with_config: assessments_with_config
    }
  end

  describe "Pure XML Parser" do
    test "XML Parser happy path", %{
      questions: questions,
      course: course,
      assessments_with_config: assessments_with_config
    } do
      for {assessment, assessment_config} <- assessments_with_config do
        xml = XMLGenerator.generate_xml_for(assessment, questions)

        assert XMLParser.parse_xml(xml, course.id, assessment_config.id) == :ok

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
          |> Map.put(:course_id, course.id)
          |> Map.put(:config_id, assessment_config.id)

        assert_map_keys(
          Map.from_struct(expected_assesment),
          Map.from_struct(assessment_db),
          ~w(title is_published config_id course_id summary_short summary_long open_at close_at)a ++
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
      questions: questions,
      course: course,
      assessments_with_config: assessments_with_config
    } do
      for {assessment, assessment_config} <- assessments_with_config do
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

        assert XMLParser.parse_xml(xml, course.id, assessment_config.id) == :ok
      end
    end

    test "PROBLEM with missing type", %{
      questions: questions,
      course: course,
      assessments_with_config: assessments_with_config
    } do
      for {assessment, assessment_config} <- assessments_with_config do
        xml =
          XMLGenerator.generate_xml_for(assessment, questions, problem_permit_keys: ~w(maxxp)a)

        assert capture_log(fn ->
                 assert(
                   XMLParser.parse_xml(xml, course.id, assessment_config.id) ==
                     {:error, {:bad_request, "Missing attribute(s) on PROBLEM"}}
                 )
               end) =~
                 "Missing attribute(s) on PROBLEM"
      end
    end

    test "PROBLEM with missing maxxp", %{
      questions: questions,
      course: course,
      assessments_with_config: assessments_with_config
    } do
      for {assessment, assessment_config} <- assessments_with_config do
        xml = XMLGenerator.generate_xml_for(assessment, questions, problem_permit_keys: ~w(type)a)

        assert capture_log(fn ->
                 assert(
                   XMLParser.parse_xml(xml, course.id, assessment_config.id) ==
                     {:error, {:bad_request, "Missing attribute(s) on PROBLEM"}}
                 )
               end) =~
                 "Missing attribute(s) on PROBLEM"
      end
    end

    test "Invalid question type", %{
      questions: questions,
      course: course,
      assessments_with_config: assessments_with_config
    } do
      for {assessment, assessment_config} <- assessments_with_config do
        xml = XMLGenerator.generate_xml_for(assessment, questions, override_type: "anu")

        assert capture_log(fn ->
                 assert(
                   XMLParser.parse_xml(xml, course.id, assessment_config.id) ==
                     {:error, {:bad_request, "Invalid question type."}}
                 )
               end) =~
                 "Invalid question type."
      end
    end

    test "Invalid question changeset", %{
      questions: questions,
      course: course,
      assessments_with_config: assessments_with_config
    } do
      for {assessment, assessment_config} <- assessments_with_config do
        questions_without_content =
          Enum.map(questions, &%{&1 | question: %{&1.question | content: ""}})

        xml = XMLGenerator.generate_xml_for(assessment, questions_without_content)

        # the error message can be quite convoluted
        assert capture_log(fn ->
                 assert(
                   {:error, {:bad_request, _error_message}} =
                     XMLParser.parse_xml(xml, course.id, assessment_config.id)
                 )
               end) =~
                 ~r/Invalid \b.*\b changeset\./
      end
    end

    test "missing PROGRAMMINGLANGUAGE", %{
      questions: questions,
      course: course,
      assessments_with_config: assessments_with_config
    } do
      for {assessment, assessment_config} <- assessments_with_config do
        xml = XMLGenerator.generate_xml_for(assessment, questions, no_programminglanguage: true)

        assert capture_log(fn ->
                 assert(
                   XMLParser.parse_xml(xml, course.id, assessment_config.id) ==
                     {:error, {:bad_request, "Missing PROGRAMMINGLANGUAGE"}}
                 )
               end) =~
                 "Missing PROGRAMMINGLANGUAGE"
      end
    end

    test "existing assessment with submissions", %{
      questions: questions,
      course: course,
      assessments_with_config: assessments_with_config
    } do
      for {assessment, assessment_config} <- assessments_with_config do
        already_open_assessment =
          Map.from_struct(%{
            assessment
            | open_at: Timex.shift(Timex.now(), days: -2),
              close_at: Timex.shift(Timex.now(), days: 2)
          })

        inserted_asst =
          %Assessment{}
          |> Assessment.changeset(already_open_assessment)
          |> Repo.insert!()

        question = insert(:programming_question, assessment_id: inserted_asst.id, assessment: nil)
        submission = insert(:submission, assessment_id: inserted_asst.id, assessment: nil)

        insert(:answer,
          question_id: question.id,
          answer: build(:programming_answer),
          submission_id: submission.id
        )

        xml = XMLGenerator.generate_xml_for(assessment, questions)

        assert capture_log(fn ->
                 assert XMLParser.parse_xml(xml, course.id, assessment_config.id) ==
                          {:ok, "Assessment has submissions, ignoring..."}
               end) =~
                 "Assessment has submissions, ignoring..."
      end
    end
  end

  describe "XML file processing" do
    test "happy path", %{
      questions: questions,
      course: course,
      assessments_with_config: assessments_with_config
    } do
      for {assessment, assessment_config} <- assessments_with_config do
        xml = XMLGenerator.generate_xml_for(assessment, questions)
        assert :ok == XMLParser.parse_xml(xml, course.id, assessment_config.id)
      end
    end

    test "empty xml file", %{assessment_configs: [config | _], course: course} do
      assert capture_log(fn ->
               assert {:error, {:bad_request, _}} = XMLParser.parse_xml("", course.id, config.id)
             end) =~ ":expected_element_start_tag"
    end

    test "valid xml file but invalid assessment xml", %{
      assessment_configs: [config | _],
      course: course
    } do
      xml = """
      <html>
      <head><title>Best markup language!</title></head>
      <body>
      <blink>Sadly this usually won't work in newer browsers</blink>
      </body>
      </html>
      """

      assert capture_log(fn ->
               {:error, {:bad_request, "Missing TASK"}} ==
                 XMLParser.parse_xml(xml, course.id, config.id)
             end) =~ "Missing TASK"
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
