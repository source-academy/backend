defmodule Cadet.Autograder.PlagiarismCheckerTest do
  use Cadet.DataCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Cadet.Autograder.PlagiarismChecker

  setup do
    HTTPoison.start()

    assessment =
      insert(:assessment, %{
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
      use_cassette "plagiarism/report_storage", custom: true do
        assert assessment.id == PlagiarismChecker.perform(assessment.id)
      end
    end
  end
end
