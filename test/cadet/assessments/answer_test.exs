defmodule Cadet.Assessments.AnswerTest do
  use Cadet.ChangesetCase, async: true

  alias Cadet.Assessments.Answer

  valid_changesets Answer do
    %{
      xp: 2,
      answer: %{}
    }

    %{
      xp: 1,
      answer: %{}
    }

    %{
      xp: 1,
      answer: %{}
    }

    %{
      xp: 100,
      answer: %{},
      raw_answer: Poison.encode!(%{answer: "This is a sample json"})
    }
  end

  invalid_changesets Answer do
    %{
      xp: -2,
      answer: %{}
    }
  end
end
