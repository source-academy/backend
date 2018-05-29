defmodule Cadet.Repo.Migrations.AddTimestampsToQuestions do
  use Ecto.Migration

  def change do
    alter table(:questions) do
      timestamps()
    end
  end
end
