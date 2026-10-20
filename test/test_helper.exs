System.put_env("LEADER", "1")

{:ok, _} = Application.ensure_all_started(:ex_machina)

ExUnit.start(capture_log: true)
Faker.start()

Ecto.Adapters.SQL.Sandbox.mode(Cadet.Repo, :manual)
