System.put_env("LEADER", "1")

{:ok, _} = Application.ensure_all_started(:ex_machina)

ExUnit.start()
Faker.start()

# Ensure test database exists and migrations are run
_ = Ecto.Adapters.Postgres.ensure_all_started(Cadet.Repo, :temporary)
{:ok, _pid} = Cadet.Repo.start_link()

case Ecto.Adapters.Postgres.storage_down(Cadet.Repo) do
  :ok -> :ok
  {:error, :already_down} -> :ok
  {:error, _} -> :ok
end

case Ecto.Adapters.Postgres.storage_up(Cadet.Repo) do
  :ok -> :ok
  {:error, :already_up} -> :ok
  {:error, _} -> :ok
end

# Run all pending migrations
:ok = Ecto.Migrator.run(Cadet.Repo, :up, all: true)

Ecto.Adapters.SQL.Sandbox.mode(Cadet.Repo, :manual)
