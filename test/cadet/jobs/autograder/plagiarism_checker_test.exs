defmodule Cadet.Autograder.PlagiarismCheckerTest do
  use Cadet.DataCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Cadet.Autograder.PlagiarismChecker

  setup do
    HTTPoison.start()

    assessment =
      insert(:assessment, %{
        id: 66,
        title: "Not the droids you are looking for"
      })

    programming_question =
      insert(:programming_question, %{
        assessment: assessment
      })

    submission =
      insert(:submission, %{
        student: insert(:user, %{role: :student}),
        assessment: assessment
      })

    insert(:mcq_question, %{
      assessment: assessment
    })

    insert(:answer, %{
      submission: submission,
      question: programming_question,
      answer: %{code: "const f = i => i === 0 ? 0 : i < 3 ? 1 : f(i-1) + f(i-2);"}
    })

    %{assessment: assessment}
  end

  describe "#perform" do
    test "calls script", %{assessment: assessment} do
      use_cassette "plagiarism/report_storage" do
        deleted_files = [
          "submissions",
          "submissions/assessment#{assessment.id}",
          "submissions/assessment#{assessment.id}/report",
          "submissions/assessment#{assessment.id}/assessment_report_#{assessment.id}.html",
          "submissions/assessment_#{assessment.id}.zip"
        ]

        {:ok, deleted_files_actual} = PlagiarismChecker.perform(assessment.id)
        assert MapSet.equal?(MapSet.new(deleted_files), MapSet.new(deleted_files_actual))
      end
    end
  end
end
