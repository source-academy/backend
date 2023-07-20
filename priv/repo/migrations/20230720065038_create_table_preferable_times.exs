defmodule Cadet.Repo.Migrations.CreateTablePreferableTimes do
  use Ecto.Migration

  def change do
    create table(:preferable_times) do
      add(:minutes, :integer, null: false)

      add(
        :notification_preference_id,
        references(:notification_preferences, on_delete: :delete_all),
        null: false
      )

      timestamps()
    end

    create(
      unique_index(:preferable_times, [:minutes, :notification_preference_id],
        name: :unique_preferable_times
      )
    )
  end
end
