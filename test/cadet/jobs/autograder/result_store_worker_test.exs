defmodule Cadet.Autograder.ResultStoreWorkerTest do
  use Cadet.DataCase

  import ExUnit.CaptureLog

  alias Cadet.Assessments.{Answer, Submission}
  alias Cadet.Autograder.ResultStoreWorker

  setup do
    assessment_config = insert(:assessment_config, %{is_grading_auto_published: true})
    assessment = insert(:assessment, %{config: assessment_config})
    question = insert(:question, %{assessment: assessment})
    submission = insert(:submission, %{status: :submitted, assessment: assessment})
    answer = insert(:answer, %{question: question, submission: submission})
    success_no_errors = %{status: :success, score: 10, max_score: 10, result: []}

    success_with_errors = %{
      result: [
        %{
          "resultType" => "error",
          "errors" => [
            %{
              "errorType" => "syntax",
              "line" => 1,
              "location" => "student",
              "errorLine" => "consst f = i => i === 0 ? 0 : i < 3 ? 1 : f(i-1) + f(i-2);",
              "errorExplanation" => "SyntaxError: Unexpected token (2:7)"
            }
          ]
        },
        %{
          "resultType" => "error",
          "errors" => [
            %{
              "errorType" => "syntax",
              "line" => 1,
              "location" => "student",
              "errorLine" => "consst f = i => i === 0 ? 0 : i < 3 ? 1 : f(i-1) + f(i-2);",
              "errorExplanation" => "SyntaxError: Unexpected token (2:7)"
            }
          ]
        }
      ],
      score: 0,
      max_score: 10,
      status: :success
    }

    failed = %{
      result: [
        %{
          "systemError" => "Autograder runtime error. Please contact a system administrator"
        }
      ],
      score: 0,
      max_score: 10,
      status: :failed
    }

    %{answer: answer, results: [failed, success_with_errors, success_no_errors]}
  end

  describe "#perform, invalid answer_id" do
    test "it captures log", %{results: [success | _]} do
      log =
        capture_log(fn ->
          ResultStoreWorker.perform(%{answer_id: 432_569, result: success})
        end)

      assert log =~ "Failed to store autograder result. answer_id: 432569"
    end
  end

  describe "#perform, valid answer_id" do
    test "before manual grading, grading auto published and manual grading required", %{
      answer: answer,
      results: results
    } do
      for result <- results do
        ResultStoreWorker.perform(%{answer_id: answer.id, result: result})

        answer =
          Answer
          |> join(:inner, [a], q in assoc(a, :question))
          |> preload([_, q], question: q)
          |> Repo.get(answer.id)

        errors_string_keys =
          Enum.map(result.result, fn err ->
            Enum.reduce(err, %{}, fn {k, v}, acc ->
              Map.put(acc, "#{k}", v)
            end)
          end)

        if result.max_score == 0 do
          assert answer.xp == 0
        else
          assert answer.xp ==
                   Integer.floor_div(
                     answer.question.max_xp * result.score,
                     result.max_score
                   )
        end

        submission = Repo.get(Submission, answer.submission_id)

        assert submission.is_grading_published == false
        assert answer.autograding_status == result.status
        assert answer.autograding_results == errors_string_keys
      end
    end

    test "before manual grading, grading auto published and manual grading not required", %{
      results: results
    } do
      assessment_config =
        insert(:assessment_config, %{is_grading_auto_published: true, is_manually_graded: false})

      assessment = insert(:assessment, %{config: assessment_config})
      question = insert(:question, %{assessment: assessment})
      submission = insert(:submission, %{status: :submitted, assessment: assessment})
      answer = insert(:answer, %{question: question, submission: submission})

      for result <- results do
        ResultStoreWorker.perform(%{answer_id: answer.id, result: result})

        answer =
          Answer
          |> join(:inner, [a], q in assoc(a, :question))
          |> preload([_, q], question: q)
          |> Repo.get(answer.id)

        errors_string_keys =
          Enum.map(result.result, fn err ->
            Enum.reduce(err, %{}, fn {k, v}, acc ->
              Map.put(acc, "#{k}", v)
            end)
          end)

        if result.max_score == 0 do
          assert answer.xp == 0
        else
          assert answer.xp ==
                   Integer.floor_div(
                     answer.question.max_xp * result.score,
                     result.max_score
                   )
        end

        submission = Repo.get(Submission, answer.submission_id)

        if result.status == :success do
          assert submission.is_grading_published == true
        else
          assert submission.is_grading_published == false
        end

        assert answer.autograding_status == result.status
        assert answer.autograding_results == errors_string_keys
      end
    end

    test "after manual grading and grading not auto published", %{results: results} do
      grader = insert(:course_registration, %{role: :staff})

      # Question uses default assessment config (is_grading_auto_published: false)
      answer =
        insert(:answer, %{
          question: insert(:question),
          submission: insert(:submission, %{status: :submitted}),
          grader_id: grader.id
        })

      for result <- results do
        ResultStoreWorker.perform(%{answer_id: answer.id, result: result})

        answer =
          Answer
          |> join(:inner, [a], q in assoc(a, :question))
          |> preload([_, q], question: q)
          |> Repo.get(answer.id)

        errors_string_keys =
          Enum.map(result.result, fn err ->
            Enum.reduce(err, %{}, fn {k, v}, acc ->
              Map.put(acc, "#{k}", v)
            end)
          end)

        if result.max_score == 0 do
          assert answer.xp == 0
        else
          assert answer.xp ==
                   Integer.floor_div(
                     answer.question.max_xp * result.score,
                     result.max_score
                   )
        end

        submission = Repo.get(Submission, answer.submission_id)

        assert submission.is_grading_published == false

        assert answer.autograding_status == result.status
        assert answer.autograding_results == errors_string_keys
      end
    end
  end
end
