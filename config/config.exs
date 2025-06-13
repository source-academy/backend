# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
import Config

config :cadet, environment: Mix.env()

# General application configuration
config :cadet,
  ecto_repos: [Cadet.Repo]

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

# Scheduler, e.g. for CS1101S
config :cadet, Cadet.Jobs.Scheduler,
  timezone: "Asia/Singapore",
  overlap: false,
  jobs: [
    # Grade assessments that close in the previous day at 00:01
    {"1 0 * * *", {Cadet.Autograder.GradingJob, :grade_all_due_yesterday, []}},
    # Compute contest leaderboard that close in the previous day at 00:01
    {"1 0 * * *", {Cadet.Assessments, :update_final_contest_leaderboards, []}},
    # Compute rolling leaderboard every 2 hours
    {"0 */2 * * *", {Cadet.Assessments, :update_rolling_contest_leaderboards, []}},
    # Collate contest entries that close in the previous day at 00:01
    {"1 0 * * *", {Cadet.Assessments, :update_final_contest_entries, []}},
    # Clean up expired exchange tokens at 00:01
    {"1 0 * * *", {Cadet.TokenExchange, :delete_expired, []}}
  ]

# Configures the endpoint
config :cadet, CadetWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "ueV6EWi+7MCMcJH/WZZVKPZbQxFix7tF1Xv9ajD4AN4jLowHbdUX33rmKWPvEEgz",
  render_errors: [view: CadetWeb.ErrorView, accepts: ~w(json)],
  pubsub_server: Cadet.PubSub

# Set Phoenix JSON library
config :phoenix, :json_library, Jason
config :phoenix_swagger, json_library: Jason

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Configure ExAWS
config :ex_aws,
  access_key_id: [{:system, "AWS_ACCESS_KEY_ID"}, {:awscli, "default", 30}, :instance_role],
  secret_access_key: [
    {:system, "AWS_SECRET_ACCESS_KEY"},
    {:awscli, "default", 30},
    :instance_role
  ],
  region: "ap-southeast-1",
  s3: [
    scheme: "https://",
    host: "s3.ap-southeast-1.amazonaws.com",
    region: "ap-southeast-1"
  ]

config :ex_aws, :hackney_opts, recv_timeout: 660_000

# Configure Arc File Upload
config :arc, virtual_host: true
# Or uncomment below to use local storage
# config :arc, storage: Arc.Storage.Local

# Configures Sentry
config :sentry,
  included_environments: [:prod],
  environment_name: Mix.env(),
  enable_source_code_context: true,
  root_source_code_path: File.cwd!(),
  context_lines: 5

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
  token_types: ["refresh"],
  # default: 60 minute
  sweep_interval: 180

config :cadet, Oban,
  repo: Cadet.Repo,
  plugins: [
    # keep
    {Oban.Plugins.Pruner, max_age: 60},
    {Oban.Plugins.Cron,
     crontab: [
       {"@daily", Cadet.Workers.NotificationWorker,
        args: %{"notification_type" => "avenger_backlog"}}
     ]}
  ],
  queues: [default: 10, notifications: 1]

config :cadet, Cadet.Mailer, adapter: Bamboo.LocalAdapter

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
