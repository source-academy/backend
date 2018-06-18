use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :cadet, CadetWeb.Endpoint,
  http: [port: 4001],
  server: false

config :cadet, environment: :test

# Reduce number of rounds for hashing to improve performance
config :pbkdf2_elixir, :rounds, 1

# Print only warnings and errors during test
config :logger, level: :warn

# Don't save secret keys in ExVCR cassettes
config :exvcr,
  filter_url_params: true,
  vcr_cassette_library_dir: "test/fixtures/vcr_cassettes"

# Configure your database
config :cadet, Cadet.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "cadet_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :cadet, Cadet.Auth.Guardian,
  issuer: "cadet",
  secret_key: "4ZxeVrSvCJlmndrFL7tBpnZsTc/rOQygVIyscAMY1oKKzkKi7hkjXl9F1f28Jap8"

config :arc, definition: Arc.Storage.Local
