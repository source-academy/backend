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
          assessment: build(:assessment)
        }
      end
    end
  end
end
