defmodule Cadet.Assessments.QuestionTypes.MCQChoiceTest do
  use Cadet.ChangesetCase, async: true

  alias Cadet.Assessments.QuestionTypes.MCQChoice

  valid_changesets MCQChoice do
    %{content: "asd", is_correct: true}
    %{content: "asd", hint: "asd", is_correct: true}
  end

  invalid_changesets MCQChoice do
    %{content: "asd"}
    %{hint: "asd"}
    %{is_correct: false}
    %{content: "asd", hint: "aaa"}
    %{content: 1, is_correct: true}
  end
end
