defmodule CadetWeb.AssessmentsControllerTest do
  use CadetWeb.ConnCase
  use Timex

  import Ecto.Query

  alias Cadet.Accounts.{Role, User}
  alias Cadet.Assessments.{Assessment, Submission}
  alias Cadet.Repo
  alias CadetWeb.AssessmentsController

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

  # All roles should see the same overview
  describe "GET /, all roles" do
    test "renders assessments overview", %{conn: conn, users: users, assessments: assessments} do
      for {_role, user} <- users do
        expected =
          assessments
          |> Map.values()
          |> Enum.map(& &1.assessment)
          |> Enum.sort(&open_at_asc_comparator/2)
          |> Enum.map(
            &%{
              "id" => &1.id,
              "title" => &1.title,
              "shortSummary" => &1.summary_short,
              "story" => &1.story,
              "number" => &1.number,
              "reading" => &1.reading,
              "openAt" => format_datetime(&1.open_at),
              "closeAt" => format_datetime(&1.close_at),
              "type" => "#{&1.type}",
              "coverImage" => Cadet.Assessments.Image.url({&1.cover_picture, &1}),
              "maxGrade" => 720,
              "attempted" => has_attempted?(user, &1)
            }
          )

        resp =
          conn
          |> sign_in(user)
          |> get(build_url())
          |> json_response(200)

        assert expected == resp
      end
    end

    test "does not render unpublished assessments", %{
      conn: conn,
      users: users,
      assessments: assessments
    } do
      for {_role, user} <- users do
        mission = assessments.mission

        {:ok, _} =
          mission.assessment
          |> Assessment.changeset(%{is_published: false})
          |> Repo.update()

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
              "story" => &1.story,
              "number" => &1.number,
              "reading" => &1.reading,
              "openAt" => format_datetime(&1.open_at),
              "closeAt" => format_datetime(&1.close_at),
              "type" => "#{&1.type}",
              "coverImage" => Cadet.Assessments.Image.url({&1.cover_picture, &1}),
              "maxGrade" => 720,
              "attempted" => has_attempted?(user, &1)
            }
          )

        resp =
          conn
          |> sign_in(user)
          |> get(build_url())
          |> json_response(200)

        assert expected == resp
      end
    end
  end

  describe "GET /assessment_id, all roles" do
    test "it renders assessment details", %{
      conn: conn,
      users: users,
      assessments: assessments
    } do
      for role <- Role.__enum_map__() do
        user = Map.get(users, role)

        for {_type, %{assessment: assessment}} <- assessments do
          expected_assessments = %{
            "id" => assessment.id,
            "title" => assessment.title,
            "type" => "#{assessment.type}",
            "story" => assessment.story,
            "number" => assessment.number,
            "reading" => assessment.reading,
            "longSummary" => assessment.summary_long,
            "missionPDF" => Cadet.Assessments.Upload.url({assessment.mission_pdf, assessment})
          }

          resp_assessments =
            conn
            |> sign_in(user)
            |> get(build_url(assessment.id))
            |> json_response(200)
            |> Map.delete("questions")

          assert expected_assessments == resp_assessments
        end
      end
    end

    test "it renders assessment questions", %{
      conn: conn,
      users: users,
      assessments: assessments
    } do
      for role <- Role.__enum_map__() do
        user = Map.get(users, role)

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
                "solutionHeader" => &1.question.solution_header
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
                  )
              }
            )

          expected_questions = expected_programming_questions ++ expected_mcq_questions

          resp_questions =
            conn
            |> sign_in(user)
            |> get(build_url(assessment.id))
            |> json_response(200)
            |> Map.get("questions", [])
            |> Enum.map(&Map.delete(&1, "answer"))
            |> Enum.map(&Map.delete(&1, "solution"))
            |> Enum.map(&Map.delete(&1, "library"))

          assert expected_questions == resp_questions
        end
      end
    end

    test "it renders assessment question libraries", %{
      conn: conn,
      users: users,
      assessments: assessments
    } do
      for role <- Role.__enum_map__() do
        user = Map.get(users, role)

        for {_type,
             %{
               assessment: assessment,
               mcq_questions: mcq_questions,
               programming_questions: programming_questions
             }} <- assessments do
          # Programming questions should come first due to seeding order

          expected_libraries =
            (programming_questions ++ mcq_questions)
            |> Enum.map(&Map.get(&1, :library))
            |> Enum.map(
              &%{
                "chapter" => &1.chapter,
                "globals" => &1.globals,
                "external" => %{
                  "name" => "#{&1.external.name}",
                  "symbols" => &1.external.symbols
                }
              }
            )

          resp_libraries =
            conn
            |> sign_in(user)
            |> get(build_url(assessment.id))
            |> json_response(200)
            |> Map.get("questions", [])
            |> Enum.map(&Map.get(&1, "library"))

          assert resp_libraries == expected_libraries
        end
      end
    end

    test "it renders solutions for ungraded assessments (path)", %{
      conn: conn,
      users: users,
      assessments: assessments
    } do
      for role <- Role.__enum_map__() do
        user = Map.get(users, role)

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
          |> sign_in(user)
          |> get(build_url(assessment.id))
          |> json_response(200)
          |> Map.get("questions", [])
          |> Enum.map(&Map.take(&1, ["solution"]))
          |> Enum.sort()

        assert expected_solutions == resp_solutions
      end
    end

    test "it does not render solutions for ungraded assessments (path)", %{
      conn: conn,
      users: users,
      assessments: assessments
    } do
      for role <- Role.__enum_map__() do
        user = Map.get(users, role)

        for {_type,
             %{
               assessment: assessment
             }} <- Map.delete(assessments, :path) do
          resp_solutions =
            conn
            |> sign_in(user)
            |> get(build_url(assessment.id))
            |> json_response(200)
            |> Map.get("questions", [])
            |> Enum.map(&Map.get(&1, ["solution"]))

          assert Enum.uniq(resp_solutions) == [nil]
        end
      end
    end

    test "it does not permit access to not yet open assessments", %{
      conn: conn,
      users: users,
      assessments: %{mission: mission}
    } do
      for role <- Role.__enum_map__() do
        user = Map.get(users, role)

        {:ok, _} =
          mission.assessment
          |> Assessment.changeset(%{
            open_at: Timex.shift(Timex.now(), days: 5),
            close_at: Timex.shift(Timex.now(), days: 10)
          })
          |> Repo.update()

        conn =
          conn
          |> sign_in(user)
          |> get(build_url(mission.assessment.id))

        assert response(conn, 401) == "Assessment not open"
      end
    end

    test "it does not permit access to unpublished assessments", %{
      conn: conn,
      users: users,
      assessments: %{mission: mission}
    } do
      for role <- Role.__enum_map__() do
        user = Map.get(users, role)

        {:ok, _} =
          mission.assessment
          |> Assessment.changeset(%{is_published: false})
          |> Repo.update()

        conn =
          conn
          |> sign_in(user)
          |> get(build_url(mission.assessment.id))

        assert response(conn, 400) == "Assessment not found"
      end
    end
  end

  describe "GET /assessment_id, student" do
    test "it renders previously submitted answers", %{
      conn: conn,
      users: %{student: student},
      assessments: assessments
    } do
      for {_type,
           %{
             assessment: assessment,
             mcq_answers: [mcq_answers | _],
             programming_answers: [programming_answers | _]
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
          |> Map.get("questions", [])
          |> Enum.map(&Map.take(&1, ["answer"]))

        assert expected_answers == resp_answers
      end
    end
  end

  describe "GET /assessment_id, non-students" do
    test "it renders empty answers", %{
      conn: conn,
      users: users,
      assessments: assessments
    } do
      for role <- [:staff, :admin] do
        user = Map.get(users, role)

        for {_type, %{assessment: assessment}} <- assessments do
          resp_answers =
            conn
            |> sign_in(user)
            |> get(build_url(assessment.id))
            |> json_response(200)
            |> Map.get("questions", [])
            |> Enum.map(&Map.get(&1, ["answer"]))

          assert Enum.uniq(resp_answers) == [nil]
        end
      end
    end
  end

  defp build_url, do: "/v1/assessments/"
  defp build_url(assessment_id), do: "/v1/assessments/#{assessment_id}"

  defp open_at_asc_comparator(x, y), do: Timex.before?(x.open_at, y.open_at)

  defp has_attempted?(user = %User{}, assessment = %Assessment{}) do
    submission =
      Submission
      |> where(student_id: ^user.id)
      |> where(assessment_id: ^assessment.id)
      |> Repo.one()

    not is_nil(submission)
  end
end
