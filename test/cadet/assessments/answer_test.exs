defmodule Cadet.Assessments.AnswerTest do
  use Cadet.ChangesetCase, async: true

  alias Cadet.Assessments.Answer

  valid_changesets Answer do
    %{
      marks: 2,
      answer: %{},
      type: :programming
    }

    %{
      marks: 1,
      answer: %{},
      type: :multiple_choice
    }
  end

  invalid_changesets Answer do
    %{
      marks: -2,
      answer: %{},
      type: :programming
    }
  end
end
