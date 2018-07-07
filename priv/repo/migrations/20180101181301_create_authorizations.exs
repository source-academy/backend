defmodule Cadet.Repo.Migrations.CreateAuthorizations do
  use Ecto.Migration

  alias Cadet.Accounts.Provider

  def up do
    Provider.create_type()

    create table(:authorizations) do
      add(:provider, :provider, null: false)
      add(:uid, :string, null: false)
      add(:token, :text, null: false)
      add(:user_id, references(:users, on_delete: :delete_all))
      add(:refresh_token, :text)
      add(:expires_at, :bigint)
    end

    create(unique_index(:authorizations, [:provider, :uid]))
    create(index(:authorizations, [:provider, :token]))
    create(index(:authorizations, [:user_id]))
  end

  def down do
    drop(table(:authorizations))
    Provider.drop_type()
  end
end
