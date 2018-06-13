defmodule Cadet.Repo.Migrations.AuthorizationRemoveToken do
  use Ecto.Migration

  def change do
    alter table(:authorizations) do
      remove(:token)
    end
  end
end
