defmodule Cadet.Assessments.AnswerTest do
  use Cadet.ChangesetCase, async: true

  alias Cadet.Assessments.Answer

  valid_changesets Answer do
    %{
      marks: 2,
      answer: %{}
    }

    %{
      marks: 1,
      answer: %{}
    }

    %{
      marks: 1,
      answer: %{}
    }

    %{
      marks: 100,
      answer: %{},
      raw_answer: Poison.encode!(%{answer: "This is a sample json"})
    }
  end

  invalid_changesets Answer do
    %{
      marks: -2,
      answer: %{}
    }
  end
end
