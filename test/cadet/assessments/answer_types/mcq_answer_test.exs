defmodule Cadet.Assessments.AnswerTypes.MCQAnswerTest do
  use Cadet.ChangesetCase, async: true
  use Cadet.DataCase

  alias Cadet.Assessments.AnswerTypes.MCQAnswer

  valid_changesets MCQAnswer do
    %{answer_choice: %{content: "asd", is_correct: true}}
  end

  invalid_changesets MCQAnswer do
    %{}
  end
end
