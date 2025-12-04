import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :cadet, CadetWeb.Endpoint,
  http: [port: 4001],
  server: false

config :cadet, environment: :test

# Print only warnings and errors during test
config :logger, level: :warning, compile_time_purge_matching: [[level_lower_than: :warning]]

config :ex_aws,
  access_key_id: "hello",
  secret_access_key: "world",
  region: "ap-southeast-1"

# Don't save secret keys in ExVCR cassettes
config :exvcr,
  filter_url_params: true,
  filter_request_headers: ["Authorization", "x-amz-content-sha256"],
  response_headers_blacklist: ["x-amz-id-2", "x-amz-request-id"],
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
      {Cadet.Auth.Providers.ADFS,
       %{
         token_endpoint: "https://my-adfs/adfs/oauth2/token"
       }},
    "test" =>
      {Cadet.Auth.Providers.Config,
       [
         %{
           token: "admin_token",
           code: "admin_code",
           name: "Test Admin",
           username: "admin"
           #  role: :admin
         },
         %{
           token: "staff_token",
           code: "staff_code",
           name: "Test Staff",
           username: "staff"
           #  role: :staff
         },
         %{
           token: "student_token",
           code: "student_code",
           name: "student 1",
           username: "E1234564"
           #  role: :student
         }
       ]},
    "saml" =>
      {Cadet.Auth.Providers.SAML,
       %{
         assertion_extractor: Cadet.Auth.Providers.NusstfAssertionExtractor,
         client_redirect_url: "https://cadet.frontend/login/callback"
       }}
  },
  autograder: [
    lambda_name: "dummy"
  ],
  uploader: [
    assets_bucket: "test-sa-assets",
    assets_prefix: "courses-test/",
    sourcecasts_bucket: "test-cadet-sourcecasts"
  ],
  remote_execution: [
    thing_prefix: "env-sling",
    thing_group: "env-sling",
    client_role_arn: "test"
  ]

config :arc, storage: Arc.Storage.Local

if "test.secrets.exs" |> Path.expand(__DIR__) |> File.exists?(),
  do: import_config("test.secrets.exs")

config :cadet, Oban,
  repo: Cadet.Repo,
  testing: :manual

config :cadet, Cadet.Mailer, adapter: Bamboo.TestAdapter

config :openai,
  # Input your own AES-256 encryption key here for encrypting LLM API keys
  encryption_key: "b4u7g0AyN3Tu2br9WSdZQjLMQ8bed/wgQWrH2x3qPdW8D55iv10+ySgs+bxDirWE"
