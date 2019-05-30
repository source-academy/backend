defmodule Cadet.Repo.Migrations.AddUnsubmitFields do
  use Ecto.Migration

  def change do
    alter table(:submissions) do
      add(:unsubmit_by_id, references(:users), null: true)
      add(:unsubmit_at, :timestamp, null: true)
    end
  end
end
