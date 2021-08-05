defmodule Cadet.Repo.Migrations.AddAssetsPrefix do
  use Ecto.Migration

  def change do
    alter table(:courses) do
      add(:assets_prefix, :string, null: true)
    end
  end
end
