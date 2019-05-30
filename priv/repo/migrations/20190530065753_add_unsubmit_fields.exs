defmodule Cadet.Repo.Migrations.AddUnsubmitFields do
  use Ecto.Migration

  def change do
    alter table(:submissions) do
      add(:unsubmitted_by_id, references(:users), null: true)
      add(:unsubmitted_at, :timestamp, null: true)
    end
  end
end
