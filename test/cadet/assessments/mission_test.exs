defmodule Cadet.Asessments.MissionTest do
  use Cadet.ChangesetCase, async: true

  alias Cadet.Assessments.Mission

  @default_library %{
    version: 1,
    globals: [],
    externals: [],
    files: []
  }

  @structure %{
    order: "1",
    category: :sidequest,
    title: "EMP",
    summary_short: "short",
    summary_long: "noooooooooooooooooooooooooooooooooooooooooothing",
    open_at: Timex.now(),
    close_at: Timex.shift(Timex.now(), weeks: 3),
    max_xp: 100,
    file: build_upload("test/fixtures/upload.txt"),
    cover_picture: nil,
    raw_library: Poison.encode!(@default_library),
    raw_questions: nil
  }

  valid_changesets Mission do
    %{@structure | order: "1"}

    %{
      @structure
      | order: "2",
        raw_questions:
          Poison.encode!(%{
            type: "mcq",
            questions: [
              %{
                content: "",
                choices: [
                  %{content: "a", hint: "hint", is_correct: false},
                  %{content: "b", hint: "hint", is_correct: true}
                ]
              }
            ]
          })
    }

    %{
      @structure
      | order: "3",
        raw_questions:
          Poison.encode!(%{
            type: "programming",
            questions: [%{content: "", solution_template: "", solution_header: "", solution: ""}]
          })
    }

    %{@structure | order: "4", cover_picture: build_upload("test/fixtures/upload.png")}
  end

  invalid_changesets Mission do
    %{summary_short: "asd", summary_long: "ada"}
    %{@structure | max_xp: -1}
    %{@structure | order: nil}
    %{@structure | open_at: Timex.now(), close_at: Timex.shift(Timex.now(), hours: -2)}
    %{@structure | raw_library: Poison.encode!(Map.delete(@default_library, :version))}
    %{@structure | raw_questions: Poison.encode!(%{type: "mcq"})}
    %{@structure | raw_questions: Poison.encode!(%{type: "mcq", questions: ""})}
  end
end
