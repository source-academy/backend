# Example production configuration file

import Config

# See https://hexdocs.pm/phoenix/Phoenix.Endpoint.html#module-runtime-configuration
# except for cors_endpoints, load_from_system_env which are custom
config :cadet, CadetWeb.Endpoint,
  # See https://hexdocs.pm/corsica/Corsica.html#module-origins
  # Remove for "*"
  cors_endpoints: "example.com",
  server: true,
  # If true, expects an environment variable PORT specifying the port to listen on
  load_from_system_env: true,
  url: [host: "api.example.com", port: 80],
  # You can specify the port here instead
  # e.g http: [compress: true, port: 4000]
  http: [compress: true],
  # Generate using `mix phx.gen.secret`
  secret_key_base: "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"

config :cadet, Cadet.Auth.Guardian,
  issuer: "cadet",
  # Generate using `mix phx.gen.secret`
  secret_key: "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"

config :cadet, Cadet.Repo,
  # Do not change this, only Postgres is supported
  # (This is here because of how configuration works in Elixir.)
  adapter: Ecto.Adapters.Postgres,
  # The AWS Secrets Manager secret name containing the database connection details
  rds_secret_name: "<unique-identifier>-cadet-db",
  # Alternatively, you can include the credentials here:
  # (comment out or remove rds_secret_name)
  # username: "postgres",
  # password: "postgres",
  # database: "cadet_stg",
  # hostname: "localhost",
  pool_size: 10

config :cadet,
  identity_providers: %{
    # # To use authentication with ADFS.
    # "nusnet" =>
    #   {Cadet.Auth.Providers.ADFS,
    #    %{
    #      # The OAuth2 token endpoint.
    #      token_endpoint: "https://my-adfs/adfs/oauth2/token"
    #    }},
    # # An example of OpenID authentication with Cognito. Any OpenID-compliant
    # # provider should work.
    # "cognito" =>
    #   {Cadet.Auth.Providers.OpenID,
    #    %{
    #      # This should match a key in openid_connect_providers below
    #      openid_provider: :cognito,
    #      # You may need to write your own claim extractor for other providers
    #      claim_extractor: Cadet.Auth.Providers.CognitoClaimExtractor
    #    }},

    # # Example SAML authentication with NUS Student IdP
    # "test_saml" =>
    #   {Cadet.Auth.Providers.SAML,
    #    %{
    #      assertion_extractor: Cadet.Auth.Providers.NusstuAssertionExtractor,
    #      client_redirect_url: "http://cadet.frontend:8000/login/callback"
    #    }},

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
  # See https://hexdocs.pm/openid_connect/readme.html
  # openid_connect_providers: [
  #   cognito: [
  #     discovery_document_uri: "",
  #     client_id: "",
  #     client_secret: "",
  #     response_type: "code",
  #     scope: "openid profile"
  #   ]
  # ],
  autograder: [
    lambda_name: "<unique-identifier>-grader"
  ],
  uploader: [
    assets_bucket: "<unique-identifier>-assets",
    assets_prefix: "courses/",
    sourcecasts_bucket: "<unique-identifier>-cadet-sourcecasts"
  ],
  # Configuration for Sling integration (executing on remote devices)
  remote_execution: [
    # Prefix for AWS IoT thing names
    thing_prefix: "<unique-identifier>-sling",
    # AWS IoT thing group to put created things into (must be set-up beforehand)
    thing_group: "<unique-identifier>-sling",
    # Role ARN to use when generating signed client MQTT-WS URLs (must be set-up beforehand)
    # Note, you need to specify the correct account ID. Find it in AWS IAM at the bottom left.
    client_role_arn: "arn:aws:iam::<account-id>:role/<unique-identifier>-cadet-frontend"
  ]

# Sentry DSN. This is only really useful to the NUS SoC deployments, but you can
# specify a DSN here if you wish to track backend errors.
# config :sentry,
#   dsn: "https://public_key/sentry.io/somethingsomething"

# If you are not running on EC2, you will need to configure an AWS access token
# for the backend to access AWS resources:
#
# This will make ExAWS read the values from the corresponding environment variables.
# config :ex_aws,
#   access_key_id: [{:system, "AWS_ACCESS_KEY_ID"}],
#   secret_access_key: [{:system, "AWS_SECRET_ACCESS_KEY"}]
#
# You can also just specify the values directly:
# config :ex_aws,
#   access_key_id: "ACCESS KEY",
#   secret_access_key: "SECRET KEY"
#
# You may also want to change the AWS or S3 region used for all resources:
# (Note, the default is ap-southeast-1 i.e. Singapore)
# config :ex_aws,
#   region: "ap-southeast-1",
#   s3: [
#     scheme: "https://",
#     host: "s3.ap-southeast-1.amazonaws.com",
#     region: "ap-southeast-1"
#   ]

# You may also want to change the timezone used for scheduled jobs
# config :cadet, Cadet.Jobs.Scheduler,
#   timezone: "Asia/Singapore",

# # Additional configuration for SAML authentication
# # For more details, see https://github.com/handnot2/samly
# config :samly, Samly.Provider,
#   idp_id_from: :path_segment,
#   service_providers: [
#     %{
#       id: "source-academy-backend",
#       certfile: "example_path/certfile.pem",
#       keyfile: "example_path/keyfile.pem"
#     }
#   ],
#   identity_providers: [
#     %{
#       id: "student",
#       sp_id: "source-academy-backend",
#       base_url: "https://example_backend/sso",
#       metadata_file: "student_idp_metadata.xml"
#     },
#     %{
#       id: "staff",
#       sp_id: "source-academy-backend",
#       base_url: "https://example_backend/sso",
#       metadata_file: "staff_idp_metadata.xml"
#     }
#   ]
