defmodule CadetWeb.Endpoint do
  use Sentry.PlugCapture
  use Phoenix.Endpoint, otp_app: :cadet

  plug(
    Corsica,
    origins: Application.get_env(:cadet, [CadetWeb.Endpoint, :cors_endpoints], "*"),
    allow_methods: :all,
    allow_headers: :all,
    expose_headers: ~w(Content-Length Content-Range),
    allow_credentials: true,
    max_age: 86_400
  )

  # For uploaded files
  plug(
    Plug.Static,
    at: "/uploads",
    from: "uploads/",
    gzip: false
  )

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    plug(Phoenix.CodeReloader)
  end

  plug(Plug.RequestId)
  plug(Plug.Logger)

  plug(
    Plug.Parsers,
    parsers: [
      :urlencoded,
      {:multipart, length: 50_000_000},
      :json
    ],
    pass: ["*/*"],
    json_decoder: Jason
  )

  plug(Sentry.PlugContext)

  plug(Plug.MethodOverride)
  plug(Plug.Head)

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  plug(
    Plug.Session,
    store: :cookie,
    key: "_cadet_key",
    signing_salt: "d3lEE99u"
  )

  plug(CadetWeb.Router)
end
