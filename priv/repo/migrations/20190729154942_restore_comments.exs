defmodule Cadet.Repo.Migrations.RestoreComments do
  use Ecto.Migration

  def change do
    alter table(:answers) do
      add(:comments, :text, null: true)
    end
  end
end
