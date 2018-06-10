defmodule Cadet.Assessments.AnswerTypes.MCQAnswerTest do
  use Cadet.ChangesetCase, async: true
  use Cadet.DataCase

  alias Cadet.Assessments.QuestionTypes.MCQChoice
  alias Cadet.Assessments.AnswerTypes.MCQAnswer

  valid_changesets MCQAnswer do
    %{answer_choice: insert(:mcq_choice)}
  end

  invalid_changesets MCQAnswer do
    %{}
  end
end
