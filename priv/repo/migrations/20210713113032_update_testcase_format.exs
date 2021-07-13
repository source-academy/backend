defmodule Cadet.Repo.Migrations.UpdateTestcaseFormat do
  use Ecto.Migration

  def change do
    alter table(:questions) do
      remove(:build_hidden_testcases)
    end
  end
end
