defmodule Cadet.Repo.Migrations.AddCollectibles do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add( :collectibles, :map, default: %{})
    end
  end
end
