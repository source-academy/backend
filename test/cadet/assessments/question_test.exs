defmodule Cadet.Assessments.QuestionTest do
  use Cadet.ChangesetCase, async: true

  alias Cadet.Assessments.Question

  valid_changesets Question do
    %{
      display_order: 2,
      title: "question",
      weight: 5,
      question: %{},
      type: :programming
    }

    %{
      display_order: 1,
      title: "mcq",
      weight: 5,
      question: %{},
      type: :multiple_choice
    }

    %{
      display_order: 5,
      title: "sample title",
      weight: 4,
      question: %{},
      type: :programming,
      raw_library: Poison.encode!(%{week: 5, globals: [], externals: [], files: []}),
      raw_question: Poison.encode!(%{question: "This is a sample json"})
    }
  end

  invalid_changesets Question do
    %{
      display_order: 2,
      title: "question",
      weight: -5,
      question: %{},
      type: :programming
    }

    %{
      display_order: 2,
      weight: 5,
      question: %{},
      type: :multiple_choice
    }
  end
end
