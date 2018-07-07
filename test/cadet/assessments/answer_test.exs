defmodule Cadet.Assessments.AnswerTest do
  use Cadet.DataCase
  use Cadet.ChangesetCase

  alias Cadet.Assessments.Answer

  describe "Changesets" do
    valid_changesets Answer do
      # TODO: Fix answer test
      # %{
      #   marks: 2,
      #   answer: %{"choice_id": "5"},
      #   submission: build(:submission),
      #   question: build(:question, %{type: :multiple_choice})
      # }

      # %{
      #   marks: 1,
      #   answer: %{}
      # }

      # %{
      #   marks: 1,
      #   answer: %{}
      # }

      # %{
      #   marks: 100,
      #   answer: %{},
      #   raw_answer: Poison.encode!(%{answer: "This is a sample json"})
      # }
    end
  end

  # valid_changesets Answer do
  #   # TODO: Fix answer test
  #   %{
  #     marks: 2,
  #     answer: %{}
  #   }

  #   # %{
  #   #   marks: 1,
  #   #   answer: %{}
  #   # }

  #   # %{
  #   #   marks: 1,
  #   #   answer: %{}
  #   # }

  #   # %{
  #   #   marks: 100,
  #   #   answer: %{},
  #   #   raw_answer: Poison.encode!(%{answer: "This is a sample json"})
  #   # }
  # end

  # invalid_changesets Answer do
  #   %{
  #     xp: -2,
  #     answer: %{}
  #   }
  # end
end
