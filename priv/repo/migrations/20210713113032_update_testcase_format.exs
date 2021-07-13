defmodule Cadet.Repo.Migrations.UpdateTestcaseFormat do
  use Ecto.Migration

  def change do
    execute(
      "update questions set question = (question - 'private' || jsonb_build_object('opaque', question->'private', 'secret', '[]'::jsonb)) where type = 'programming' and build_hidden_testcases;"
    )

    execute(
      "update questions set question = (question - 'private' || jsonb_build_object('secret', question->'private', 'opaque', '[]'::jsonb)) where type = 'programming' and not build_hidden_testcases;"
    )

    alter table(:questions) do
      remove(:build_hidden_testcases)
    end
  end
end
