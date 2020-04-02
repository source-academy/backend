defmodule Cadet.Repo.Migrations.AddUserGameStates do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:game_states, :map, default: %{collectibles: %{}, save_data: %{
        action_sequence: [], start_location: ""
      }})
    end
  end
end
