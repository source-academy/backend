defmodule Cadet.Assessments.SubmissionTest do
  use Cadet.ChangesetCase, async: true

  alias Cadet.Assessments.Submission

  valid_changesets Submission do
    %{
      status: :submitted,
      submitted_at: Timex.now() |> Timex.to_unix() |> Integer.to_string(),
      override_xp: 100
    }
  end

end
