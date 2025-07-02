import Config

# Do not print debug messages in production
config :logger, level: :info

# Add the CloudWatch logger backend in production
config :logger, backends: [:console, {Cadet.Logger.CloudWatchLogger, :cloudwatch_logger}]

# Configure CloudWatch Logger
config :logger, :cloudwatch_logger,
  level: :info,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id],
  log_group: "cadet-logs",
  log_stream: "#{node()}-#{:os.system_time(:second)}"

# ## SSL Support
#
# To get SSL working, you will need to add the `https` key
# to the previous section and set your `:url` port to 443:
#
#     config :cadet, CadetWeb.Endpoint,
#       ...
#       url: [host: "example.com", port: 443],
#       https: [:inet6,
#               port: 443,
#               keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
#               certfile: System.get_env("SOME_APP_SSL_CERT_PATH")]
#
# Where those two env variables return an absolute path to
# the key and cert in disk or a relative path inside priv,
# for example "priv/ssl/server.key".
#
# We also recommend setting `force_ssl`, ensuring no data is
# ever sent via http, always redirecting to https:
#
#     config :cadet, CadetWeb.Endpoint,
#       force_ssl: [hsts: true]
#
# Check `Plug.SSL` for all available options in `force_ssl`.

# ## Using releases
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start the server for all endpoints:
#
#     config :phoenix, :serve_endpoints, true
#
# Alternatively, you can configure exactly which server to
# start per endpoint:
#
#     config :cadet, CadetWeb.Endpoint, server: true
#

config :ex_aws,
  access_key_id: [:instance_role],
  secret_access_key: [:instance_role]

config :cadet, Cadet.Mailer, adapter: Bamboo.SesAdapter
