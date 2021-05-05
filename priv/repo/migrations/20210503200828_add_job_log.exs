defmodule Elixir.Cadet.Repo.Migrations.AddJobLog do
  use Ecto.Migration

  def change do
    create table(:job_log) do
      add(:name, :string, null: false)
      add(:last_run, :utc_datetime, null: false)
    end

    unique_index(:job_log, :name)
  end
end
