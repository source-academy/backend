defmodule Cadet.Assessments.QuestionTypes.MCQQuestionTest do
  use Cadet.ChangesetCase, async: true

  alias Cadet.Assessments.QuestionTypes.MCQQuestion

  valid_changesets MCQQuestion do
    %{content: "asd", choices: [%{content: "asd", is_correct: true}]}

    %{
      raw_mcqquestion:
        "{\"content\":\"asd\",\"choices\":[{\"is_correct\":true,\"content\":\"asd\"}]}"
    }
  end

  invalid_changesets MCQQuestion do
    %{content: "asd"}
    %{content: "asd", choices: [%{content: "asd", is_correct: false}]}
  end
end
