defmodule Cadet.Assessments.QuestionTypes.MCQChoiceTest do
  use Cadet.ChangesetCase, async: true

  alias Cadet.Assessments.QuestionTypes.MCQChoice

  valid_changesets MCQChoice do
    %{choice_id: 1, content: "asd", is_correct: true}
    %{choice_id: 4, content: "asd", hint: "asd", is_correct: true}
  end

  invalid_changesets MCQChoice do
    %{choice_id: 1, content: "asd"}
    %{choice_id: 1, hint: "asd"}
    %{choice_id: 1, is_correct: false}
    %{choice_id: 1, content: "asd", hint: "aaa"}
    %{content: 1, is_correct: true}
    %{choice_id: 6, content: 1, is_correct: true}
    %{choice_id: -1, content: 1, is_correct: true}
  end
end
