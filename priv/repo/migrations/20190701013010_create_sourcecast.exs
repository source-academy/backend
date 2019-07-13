defmodule Cadet.Repo.Migrations.CreateSourcecast do
  use Ecto.Migration

  def change do
    create table(:sourcecasts) do
      add(:title, :string, null: false)
      add(:description, :string)
      add(:uploader_id, references(:users, on_delete: :nilify_all))
      add(:audio, :string)
      add(:playbackData, :text)
      timestamps()
    end

    create(index(:sourcecasts, [:uploader_id]))
  end
end
