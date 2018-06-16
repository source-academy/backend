defmodule Cadet.Assessments.AnswerTypes.ProgrammingAnswerTest do
  use Cadet.ChangesetCase, async: true
  use Cadet.DataCase

  alias Cadet.Assessments.AnswerTypes.ProgrammingAnswer

  valid_changesets ProgrammingAnswer do
    %{code: "This is some code"}
  end

  invalid_changesets ProgrammingAnswer do
    %{}
  end
end
