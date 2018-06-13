defmodule Cadet.Repo.Migrations.CreateGradings do
  use Ecto.Migration

  def change do
    create table(:gradings) do
      add(:weight, :integer)
      add(:marks, :integer)
      add(:comment, :string)

      timestamps()
    end
  end
end
