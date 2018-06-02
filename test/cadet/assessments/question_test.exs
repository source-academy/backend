defmodule Cadet.Assessments.QuestionTest do
  use Cadet.ChangesetCase, async: true

  alias Cadet.Assessments.Question

  valid_changesets Question do
    %{
      display_order: 2,
      title: "question",
      weight: 5,
      question: %{},
      type: :programming,
    }
    %{
      display_order: 1,
      title: "mcq",
      weight: 5,
      question: %{},
      type: :multiple_choice,
    }
  end

  invalid_changesets Question do
    %{
      display_order: 2,
      title: "question",
      weight: -5,
      question: %{},
      type: :programming,
    }

    %{
      display_order: 2,
      weight: 5,
      question: %{},
      type: :multiple_choice,
    }
  end
end
