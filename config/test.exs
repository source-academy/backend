use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :cadet, CadetWeb.Endpoint,
  http: [port: 4001],
  server: false

# Reduce number of rounds for hashing to improve performance
config :pbkdf2_elixir, :rounds, 1

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :cadet, Cadet.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "cadet_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
