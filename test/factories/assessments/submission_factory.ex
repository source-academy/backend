defmodule Cadet.Assessments.SubmissionFactory do
  @moduledoc """
  Factory for the Submission entity
  """

  defmacro __using__(_opts) do
    quote do
      alias Cadet.Assessments.Submission

      def submission_factory do
        %Submission{
          student: build(:course_registration, %{role: :student}),
          team: nil,
          assessment: build(:assessment),
          is_grading_published: false
        }
      end
    end
  end
end
