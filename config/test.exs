use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :cadet, CadetWeb.Endpoint,
  http: [port: 4001],
  server: false

config :cadet, environment: :test

# Print only warnings and errors during test
config :logger, level: :warn, compile_time_purge_level: :warn

config :ex_aws,
  access_key_id: "hello",
  secret_access_key: "world",
  region: "ap-southeast-1"

# Don't save secret keys in ExVCR cassettes
config :exvcr,
  filter_url_params: true,
  vcr_cassette_library_dir: "test/fixtures/vcr_cassettes",
  custom_cassette_library_dir: "test/fixtures/custom_cassettes"

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

config :cadet,
  plagiarism_check_vars: [
    bucket_name: "plagiarism-reports",
    plagiarism_script_path: "../path/to/plagiarism/script"
  ]
