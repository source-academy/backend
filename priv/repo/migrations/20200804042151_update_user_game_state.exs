defmodule Cadet.Repo.Migrations.UpdateUserGameState do
  use Ecto.Migration

  def change do
    alter table(:users) do
      modify(:game_states, :map, default: %{})
    end
  end
end
