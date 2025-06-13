defmodule Cadet.Repo.Migrations.SubmissionsAddSubmittedAtColumn do
  use Ecto.Migration

  def change do
    alter table(:submissions) do
      add(:submitted_at, :timestamp, null: true)
    end
  end
end
