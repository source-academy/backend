defmodule Cadet.Repo.Migrations.AddGameStates do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:game_states, :map, default: %{collectibles: %{}, completed_quests: []})
    end
  end
end
