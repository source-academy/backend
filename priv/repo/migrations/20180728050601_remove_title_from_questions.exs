defmodule Cadet.Repo.Migrations.RemoveTitleFromQuestions do
  use Ecto.Migration

  def change do
    alter table(:questions) do
      remove(:title)
    end
  end
end
