defmodule Cadet.Repo.Migrations.CreateSourcecast do
  use Ecto.Migration

  def change do
    create table(:sourcecasts) do
      add(:name, :string, null: false)
      add(:uploader_id, references(:users, on_delete: :nilify_all))
      add(:audio, :string)
      add(:deltas, :text)
      timestamps()
    end

    create(index(:sourcecasts, [:uploader_id]))
  end
end
