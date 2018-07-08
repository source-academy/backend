defmodule Cadet.Assessments.SubmissionTest do
  use Cadet.ChangesetCase, async: true

  alias Cadet.Assessments.Submission

  valid_changesets Submission do
    %{}
  end
end
