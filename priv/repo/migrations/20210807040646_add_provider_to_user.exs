defmodule Cadet.Repo.Migrations.AddProviderToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:provider, :string, null: true)
    end

    drop(unique_index(:users, [:username], name: "users_nusnet_id_index"))
    create(unique_index(:users, [:username, :provider]))

    execute("update users set provider = split_part(username, '/', 1)")

    execute("update users set username = substring(username from char_length(provider) + 2)")

    alter table(:users) do
      modify(:provider, :string, null: false)
    end
  end
end
