use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :cadet, CadetWeb.Endpoint,
  http: [port: 4001],
  server: false

config :cadet, environment: :test

# Print only warnings and errors during test
config :logger, level: :warn, compile_time_purge_matching: [[level_lower_than: :warn]]

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

config :cadet,
  identity_providers: %{
    "nusnet_id" =>
      {Cadet.Auth.Providers.LumiNUS,
       %{
         api_key: "API_KEY",
         module_code: "CS1101S"
       }},
    "test" =>
      {Cadet.Auth.Providers.Config,
       [
         %{
           token: "admin_token",
           code: "admin_code",
           name: "Test Admin",
           username: "admin",
           role: :admin
         },
         %{
           token: "staff_token",
           code: "staff_code",
           name: "Test Staff",
           username: "staff",
           role: :staff
         },
         %{
           token: "student_token",
           code: "student_code",
           name: "Test Student",
           username: "student",
           role: :student
         }
       ]}
  },
  updater: [
    cs1101s_repository: "git@dummy:dummy.git",
    cs1101s_rsa_key: "/home/test/dummy"
  ],
  autograder: [
    lambda_name: "dummy"
  ],
  uploader: [
    materials_bucket: "test-cadet-materials",
    sourcecasts_bucket: "test-cadet-sourcecasts"
  ]

config :arc, storage: Arc.Storage.Local
