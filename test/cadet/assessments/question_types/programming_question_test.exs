defmodule Cadet.Assessments.QuestionTypes.ProgrammingQuestionTest do
  use Cadet.ChangesetCase, async: true

  alias Cadet.Assessments.QuestionTypes.ProgrammingQuestion

  valid_changesets ProgrammingQuestion do
    %{content: "asd", solution_template: "asd", solution_header: "asd", solution: "asd"}

    %{
      raw_programmingquestion:
        "{\"solution_template\":\"asd\",\"solution_header\":\"asd\",\"solution\":\"asd\",\"content\":\"asd\"}"
    }
  end

  invalid_changesets ProgrammingQuestion do
    %{content: "asd"}
  end
end
