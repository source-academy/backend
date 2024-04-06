defmodule Cadet.Repo.Migrations.AddLastModifiedToAnswers do
  use Ecto.Migration

  def change do
    alter table(:answers) do
      add(:last_modified_at, :utc_datetime, default: fragment("CURRENT_TIMESTAMP"))
    end
  end
end
