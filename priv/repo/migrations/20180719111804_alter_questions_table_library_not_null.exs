defmodule Cadet.Repo.Migrations.AlterQuestionsTableLibraryNotNull do
  use Ecto.Migration

  def change do
    alter table(:questions) do
      modify(:library, :map, null: false)
    end
  end
end
