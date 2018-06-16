defmodule Cadet.Assessments.AnswerTypes.MCQAnswerTest do
  use Cadet.ChangesetCase, async: true

  import Ecto.Changeset
  alias Cadet.Assessments.AnswerTypes.MCQAnswer

  valid_changesets MCQAnswer do
    %{choice_id: 1}
    %{choice_id: 2}
    %{choice_id: 3}
    %{choice_id: 4}
  end
<<<<<<< Updated upstream
  
=======

>>>>>>> Stashed changes
  invalid_changesets MCQAnswer do
    %{choice_id: 0}
    %{choice_id: -2}
    %{choice_id: 5}
  end
end
