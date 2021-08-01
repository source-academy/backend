System.put_env("LEADER", "1")

{:ok, _} = Application.ensure_all_started(:ex_machina)

ExUnit.start()
Faker.start()

Ecto.Adapters.SQL.Sandbox.mode(Cadet.Repo, :manual)
