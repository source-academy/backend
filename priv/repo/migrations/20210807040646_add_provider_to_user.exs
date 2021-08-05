defmodule Cadet.Repo.Migrations.AddProviderToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:provider, :string, null: true)
    end

    execute("update users set provider = 'luminus' where username like 'luminus/%'")

    execute(
      "update users set username = replace(username, 'luminus/', '') where username like 'luminus/%'"
    )

    execute("update users set provider = 'test' where username like 'test/%'")

    execute(
      "update users set username = replace(username, 'test/', '') where username like 'test/%'"
    )

    alter table(:users) do
      modify(:provider, :string, null: false)
    end
  end
end
