defmodule Cadet.Assessments.SubmissionVotesFactory do
  @moduledoc """
  Factory for the SubmissionVote entity
  """

  defmacro __using__(_opts) do
    quote do
      alias Cadet.Assessments.SubmissionVotes

      def submission_vote_factory do
        %SubmissionVotes{
          voter: build(:course_registration, %{role: :student}),
          question: build(:voting_question),
          submission: build(:submission)
        }
      end
    end
  end
end
