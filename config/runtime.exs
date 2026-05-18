import Config

# This file is executed after the code compilation on all environments.
# It contains runtime configuration that's evaluated when the system starts.

# Configure the port from environment variable if set
if port = System.get_env("PORT") do
  config :cadet, CadetWeb.Endpoint, http: [:inet6, port: String.to_integer(port)]
end
