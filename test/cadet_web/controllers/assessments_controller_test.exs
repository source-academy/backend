defmodule CadetWeb.AssessmentsControllerTest do
  use CadetWeb.ConnCase
  use Timex

  alias CadetWeb.AssessmentsController
  alias Cadet.Assessments.Assessment
  alias Cadet.Accounts.Role
  alias Cadet.Repo

  setup do
    Cadet.Test.Seeds.assessments()
  end

  test "swagger" do
    AssessmentsController.swagger_definitions()
    AssessmentsController.swagger_path_index(nil)
    AssessmentsController.swagger_path_show(nil)
  end

  describe "GET /, unauthenticated" do
    test "unauthorized", %{conn: conn} do
      conn = get(conn, build_url())
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  describe "GET /:assessment_id, unauthenticated" do
    test "unauthorized", %{conn: conn} do
      conn = get(conn, build_url(1))
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  # All roles should see the same overview page
  for role <- Role.__enum_map__() do
    describe "GET /, #{role}" do
      @tag authenticate: role
      test "renders assessments overview", %{conn: conn, assessments: assessments} do
        conn = get(conn, build_url())

        expected =
          assessments
          |> Map.values()
          |> Enum.map(fn a -> a.assessment end)
          |> Enum.sort(&open_at_asc_comparator/2)
          |> Enum.map(
            &%{
              "id" => &1.id,
              "title" => &1.title,
              "shortSummary" => &1.summary_short,
              "openAt" => format_datetime(&1.open_at),
              "closeAt" => format_datetime(&1.close_at),
              "type" => "#{&1.type}",
              "coverImage" => Cadet.Assessments.Image.url({&1.cover_picture, &1}),
              "maximumEXP" => 720
            }
          )

        assert ^expected = json_response(conn, 200)
      end

      @tag authenticate: role
      test "does not render unpublished assessments", %{conn: conn, assessments: assessments} do
        mission = assessments.mission

        {:ok, _} =
          mission.assessment
          |> Assessment.changeset(%{is_published: false})
          |> Repo.update()

        conn = get(conn, build_url())

        expected =
          assessments
          |> Map.delete(:mission)
          |> Map.values()
          |> Enum.map(fn a -> a.assessment end)
          |> Enum.sort(&open_at_asc_comparator/2)
          |> Enum.map(
            &%{
              "id" => &1.id,
              "title" => &1.title,
              "shortSummary" => &1.summary_short,
              "openAt" => format_datetime(&1.open_at),
              "closeAt" => format_datetime(&1.close_at),
              "type" => "#{&1.type}",
              "coverImage" => Cadet.Assessments.Image.url({&1.cover_picture, &1}),
              "maximumEXP" => 720
            }
          )

        assert ^expected = json_response(conn, 200)
      end
    end
  end

  describe "GET /assessment_id, student" do
    test "it renders assessment details", %{
      conn: conn,
      users: %{students: [student | _students]},
      assessments: assessments
    } do
      for {_type, %{assessment: assessment}} <- assessments do
        expected_assessments = %{
          "id" => assessment.id,
          "title" => assessment.title,
          "type" => "#{assessment.type}",
          "longSummary" => assessment.summary_long,
          "missionPDF" => Cadet.Assessments.Upload.url({assessment.mission_pdf, assessment})
        }

        resp_assessments =
          conn
          |> sign_in(student)
          |> get(build_url(assessment.id))
          |> json_response(200)
          |> Map.delete("questions")

        assert ^expected_assessments = resp_assessments
      end
    end

    test "it renders assessment questions", %{
      conn: conn,
      users: %{students: [student | _students]},
      assessments: assessments
    } do
      for {_type,
           %{
             assessment: assessment,
             mcq_questions: mcq_questions,
             programming_questions: programming_questions
           }} <- assessments do
        # Programming questions should come first due to seeding order
        expected_programming_questions =
          Enum.map(
            programming_questions,
            &%{
              "id" => &1.id,
              "type" => "#{&1.type}",
              "content" => &1.question.content,
              "solutionTemplate" => &1.question.solution_template,
              "solutionHeader" => &1.question.solution_header,
              "library" =>
                if &1.library do
                  %{
                    "globals" => &1.library.globals,
                    "files" => &1.library.files,
                    "externals" => &1.library.externals,
                    "chapter" => &1.library.chapter
                  }
                end
            }
          )

        expected_mcq_questions =
          Enum.map(
            mcq_questions,
            &%{
              "id" => &1.id,
              "type" => "#{&1.type}",
              "content" => &1.question.content,
              "choices" =>
                Enum.map(
                  &1.question.choices,
                  fn choice ->
                    %{
                      "id" => choice.choice_id,
                      "content" => choice.content,
                      "hint" => choice.hint
                    }
                  end
                ),
              "library" =>
                if &1.library do
                  %{
                    "globals" => &1.library.globals,
                    "files" => &1.library.files,
                    "externals" => &1.library.externals,
                    "chapter" => &1.library.chapter
                  }
                end
            }
          )

        expected_questions = expected_programming_questions ++ expected_mcq_questions

        resp_questions =
          conn
          |> sign_in(student)
          |> get(build_url(assessment.id))
          |> json_response(200)
          |> Map.get("questions")
          |> Enum.map(&Map.delete(&1, "answer"))
          |> Enum.map(&Map.delete(&1, "solution"))

        assert expected_questions == resp_questions
      end
    end

    test "it renders previously submitted answers", %{
      conn: conn,
      users: %{students: [student | _students]},
      assessments: assessments
    } do
      for {_type,
           %{
             assessment: assessment,
             mcq_answers: [mcq_answers | _mcq_answers],
             programming_answers: [programming_answers | _programming_answers]
           }} <- assessments do
        # Programming questions should come first due to seeding order

        expected_programming_answers =
          Enum.map(programming_answers, &%{"answer" => &1.answer.code})

        expected_mcq_answers = Enum.map(mcq_answers, &%{"answer" => &1.answer.choice_id})
        expected_answers = expected_programming_answers ++ expected_mcq_answers

        resp_answers =
          conn
          |> sign_in(student)
          |> get(build_url(assessment.id))
          |> json_response(200)
          |> Map.get("questions")
          |> Enum.map(&Map.take(&1, ["answer"]))

        assert expected_answers == resp_answers
      end
    end

    test "it renders mcq solutions for ungraded assessments (path)", %{
      conn: conn,
      users: %{students: [student | _students]},
      assessments: assessments
    } do
      %{
        assessment: assessment,
        mcq_questions: mcq_questions,
        programming_questions: programming_questions
      } = assessments.path

      # Seeds set solution as 0
      expected_mcq_solutions = Enum.map(mcq_questions, fn _ -> %{"solution" => 0} end)

      expected_programming_solutions =
        Enum.map(programming_questions, &%{"solution" => &1.question.solution})

      expected_solutions = Enum.sort(expected_mcq_solutions ++ expected_programming_solutions)

      resp_solutions =
        conn
        |> sign_in(student)
        |> get(build_url(assessment.id))
        |> json_response(200)
        |> Map.get("questions")
        |> Enum.map(&Map.take(&1, ["solution"]))
        |> Enum.sort()

      assert expected_solutions == resp_solutions
    end

    test "it does not render mcq solutions for ungraded assessments (path)", %{
      conn: conn,
      users: %{students: [student | _students]},
      assessments: assessments
    } do
    end
  end

  # for role <- [:staff, :admin] do
  #   describe "GET /assessment_id, #{role}" do
  #     it "renders assessment details" do
  #     end
  #   end
  # end

  defp build_url, do: "/v1/assessments/"
  defp build_url(assessment_id), do: "/v1/assessments/#{assessment_id}"

  defp open_at_asc_comparator(x, y), do: Timex.before?(x.open_at, y.open_at)
end
