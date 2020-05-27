defmodule Cadet.Repo.Migrations.OverhaulAuth do
  use Ecto.Migration

  def up do
    rename(table(:users), :nusnet_id, to: :username)
    drop(table(:authorizations))
    Ecto.Migration.execute("DROP TYPE provider")
  end
end
