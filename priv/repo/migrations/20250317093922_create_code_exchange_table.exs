defmodule Cadet.Repo.Migrations.CreateCodeExchangeTable do
  use Ecto.Migration

  def change do
    create table(:code_exchange) do
      add(:code, :string, null: false)
      add(:generated_at, :utc_datetime_usec, null: false)
      add(:expires_at, :utc_datetime_usec, null: false)
      add(:user_id, references(:users), null: false)
      timestamps()
    end
  end
end
