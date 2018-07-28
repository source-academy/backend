# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :cadet,
  ecto_repos: [Cadet.Repo],
  # milliseconds
  updater: [interval: 5 * 60 * 1000]

# Scheduler, e.g. for CS1101S
config :cadet, Cadet.Updater.Scheduler,
  jobs: [
    {"* * * * *", {Cadet.Updater.CS1101S, :update, []}}
  ]

# Configures the endpoint
config :cadet, CadetWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "ueV6EWi+7MCMcJH/WZZVKPZbQxFix7tF1Xv9ajD4AN4jLowHbdUX33rmKWPvEEgz",
  render_errors: [view: CadetWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Cadet.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Configure Arc File Upload
config :arc, storage: Arc.Storage.Local

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

# Configure Phoenix Swagger
config :cadet, :phoenix_swagger,
  swagger_files: %{
    "priv/static/swagger.json" => [
      router: CadetWeb.Router
    ]
  }

# Configure GuardianDB
config :guardian, Guardian.DB,
  repo: Cadet.Repo,
  # default
  schema_name: "guardian_tokens",
  # store all token types if not set
  token_types: ["access"],
  # default: 60 minute
  sweep_interval: 60

# Configure :ex_aws
config :ex_aws,
  access_key_id: {:system, "AWS_ACCESS_KEY_ID"},
  secret_access_key: {:system, "AWS_SECRET_ACCESS_KEY"},
  s3: [
    scheme: "https://",
    host: "sreyansapitest.s3-ap-southeast-1.amazonaws.com",
    region: "ap-southeast-1"
  ]