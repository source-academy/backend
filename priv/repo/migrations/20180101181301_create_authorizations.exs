defmodule Cadet.Repo.Migrations.CreateAuthorizations do
  use Ecto.Migration

  def up do
    Ecto.Migration.execute("CREATE TYPE provider AS ENUM ('nusnet_id')")

    create table(:authorizations) do
      add(:provider, :provider, null: false)
      add(:uid, :string, null: false)
      add(:user_id, references(:users, on_delete: :delete_all))
      add(:expires_at, :bigint)
    end

    create(unique_index(:authorizations, [:provider, :uid]))
    create(index(:authorizations, [:provider]))
    create(index(:authorizations, [:uid]))
    create(index(:authorizations, [:user_id]))
  end

  def down do
    drop(table(:authorizations))
    Ecto.Migration.execute("DROP TYPE provider")
  end
end
