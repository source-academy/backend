defmodule Cadet.Repo.Migrations.CreateCells do
  use Ecto.Migration

  def change do
    create table(:cells) do
      add(:iscode, :boolean, null: false)
      add(:content, :string, null: false)
      add(:output, :string, null: false)
      add(:index, :integer, null: false)

      add(:notebook, references(:notebooks), null: false)
      add(:environment, references(:environments), null: false)

      timestamps()
    end

    create(index(:cells, [:notebook]))
    create(index(:cells, [:environment]))
  end
end
