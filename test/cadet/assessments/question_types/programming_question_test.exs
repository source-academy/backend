defmodule Cadet.Assessments.QuestionTypes.ProgrammingQuestionTest do
  use Cadet.ChangesetCase, async: true

  alias Cadet.Assessments.QuestionTypes.ProgrammingQuestion

  valid_changesets ProgrammingQuestion do
    %{
      content: "asd",
      solution_template: "asd",
      solution: "asd",
      library: %{version: 1}
    }

    %{
      raw_programmingquestion:
        "{\"solution_template\":\"asd\",\"solution_header\":\"asd\",\"solution\":\"asd\",\"content\":\"asd\",\"library\":{\"version\":1}}"
    }
  end

  invalid_changesets ProgrammingQuestion do
    %{content: "asd"}

    %{
      content: "asd",
      solution_template: "asd",
      solution_header: "asd",
      library: %{globals: ["a"]}
    }
  end
end
