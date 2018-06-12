defmodule Cadet.Assessments.AnswerTypes.ProgrammingAnswerTest do
  use Cadet.ChangesetCase, async: true
  use Cadet.DataCase

  alias Cadet.Assessments.AnswerTypes.ProgrammingAnswer

  valid_changesets ProgrammingAnswer do
    %{solution_code: "This is some code"}
  end

  invalid_changesets ProgrammingAnswer do
    %{}
  end
end
<<<<<<< HEAD
  
=======
>>>>>>> d08d50a55138354557a30d45d5423d8531f5c5b1
