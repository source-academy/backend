defmodule CadetWeb.VersionsControllerTest do
  use CadetWeb.ConnCase, async: false

  import Ecto.Query

  alias Cadet.Assessments.Version
  alias Cadet.Repo
  alias CadetWeb.VersionsController

  test "swagger" do
    VersionsController.swagger_definitions()
    VersionsController.swagger_path_index(nil)
    VersionsController.swagger_path_show(nil)
    VersionsController.swagger_path_save(nil)
    VersionsController.swagger_path_name(nil)
  end

  setup do
    course = insert(:course)
    config = insert(:assessment_config, %{course: course})
    assessment = insert(:assessment, %{is_published: true, course: course, config: config})
    programming_question = insert(:programming_question, %{assessment: assessment})

    %{
      course: course,
      assessment: assessment,
      programming_question: programming_question
    }
  end

  for role <- ~w(student staff admin)a do
    describe "GET /assessments/question/{questionId}/versions, #{role}" do
      @tag authenticate: role
      test "renders list of version overviews", %{
        conn: conn,
        assessment: assessment,
        programming_question: programming_question
      } do
        course_reg = conn.assigns.test_cr
        course_id = conn.assigns.course_id

        submission = insert(:submission, %{assessment: assessment, student: course_reg})
        answer = insert(:answer, %{submission: submission, question: programming_question})

        versions = [
          insert(:version, %{
            content: %{"code" => "console.log('version 1');"},
            answer: answer,
            name: "v1"
          }),
          insert(:version, %{
            content: %{"code" => "console.log('version 2');"},
            answer: answer,
            name: "v2"
          })
        ]

        expected =
          versions
          |> Enum.sort_by(& &1.id)
          |> Enum.map(fn v ->
            %{
              "id" => v.id,
              "name" => v.name,
              "inserted_at" => format_timestamp(v.inserted_at),
              "updated_at" => format_timestamp(v.updated_at)
            }
          end)

        resp =
          conn
          |> get(build_url(course_id, programming_question.id, ""))
          |> json_response(200)

        assert expected == resp
      end
    end

    describe "GET /assessments/question/{questionId}/versions/{versionId}, #{role}" do
      @tag authenticate: role
      test "renders a single version", %{
        conn: conn,
        assessment: assessment,
        programming_question: programming_question
      } do
        course_reg = conn.assigns.test_cr
        course_id = conn.assigns.course_id

        submission = insert(:submission, %{assessment: assessment, student: course_reg})
        answer = insert(:answer, %{submission: submission, question: programming_question})

        version =
          insert(:version, %{
            content: %{"code" => "console.log('version 1');"},
            answer: answer,
            name: "v1"
          })

        expected = %{
          "id" => version.id,
          "name" => version.name,
          "content" => version.content,
          "answer_id" => version.answer_id,
          "inserted_at" => format_timestamp(version.inserted_at),
          "updated_at" => format_timestamp(version.updated_at)
        }

        resp =
          conn
          |> get(build_url(course_id, programming_question.id, "#{version.id}"))
          |> json_response(200)

        assert expected == resp
      end
    end

    describe "POST /assessments/question/{questionId}/versions/save, #{role}" do
      @tag authenticate: role
      test "first submission successfully saves a new version of the answer", %{
        conn: conn,
        assessment: assessment,
        programming_question: programming_question
      } do
        course_reg = conn.assigns.test_cr
        course_id = conn.assigns.course_id

        save_conn =
          post(conn, build_url(course_id, programming_question.id, "save"), %{
            content: "console.log('version 1');"
          })

        assert response(save_conn, 200) =~ "OK"

        assert get_latest_version_value(programming_question, assessment, course_reg) ==
                 "console.log('version 1');"
      end
    end

    describe "PUT /assessments/question/{questionId}/versions/{versionId}/name, #{role}" do
      @tag authenticate: role
      test "successfully renames a version", %{
        conn: conn,
        assessment: assessment,
        programming_question: programming_question
      } do
        course_reg = conn.assigns.test_cr
        course_id = conn.assigns.course_id

        submission = insert(:submission, %{assessment: assessment, student: course_reg})
        answer = insert(:answer, %{submission: submission, question: programming_question})

        version =
          insert(:version, %{
            content: %{"code" => "console.log('version 1');"},
            answer: answer,
            name: "v1"
          })

        name_conn =
          put(conn, build_url(course_id, programming_question.id, "#{version.id}/name"), %{
            name: "renamed"
          })

        assert response(name_conn, 200) =~ "OK"
        updated_version = Repo.get(Version, version.id)
        assert updated_version.name == "renamed"
      end
    end
  end

  defp build_url(course_id, question_id, action) do
    "/v2/courses/#{course_id}/assessments/question/#{question_id}/versions/#{action}"
  end

  defp get_latest_version_value(question, assessment, course_reg) do
    version =
      Version
      |> join(:inner, [v], a in assoc(v, :answer))
      |> join(:inner, [v, a], s in assoc(a, :submission))
      |> where([v, a, s], a.question_id == ^question.id)
      |> where([v, a, s], s.student_id == ^course_reg.id)
      |> where([v, a, s], s.assessment_id == ^assessment.id)
      |> order_by([v], desc: v.id)
      |> limit(1)
      |> Repo.one()

    if version do
      case question.type do
        :programming -> Map.get(version.content, "code")
      end
    end
  end

  defp format_timestamp(nil), do: nil

  defp format_timestamp(ts) do
    ts |> DateTime.to_iso8601()
  end
end
