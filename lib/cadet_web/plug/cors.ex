defmodule CadetWeb.Plug.CORS do
  @moduledoc """
  A plug that adds CORS headers via `Corsica`, reading the allowed origins from
  the application environment at runtime.

  `CadetWeb.Endpoint` initialises its plugs at compile time, but
  `:cors_endpoints` is only known once the runtime configuration file has been
  loaded (see `config/releases.exs`). Initialising `Corsica` inline in the
  endpoint would therefore always bake in the compile-time default of `"*"`,
  which, combined with `allow_credentials: true`, allows any origin to make
  credentialed requests.
  """

  @corsica_opts [
    allow_methods: :all,
    allow_headers: :all,
    expose_headers: ~w(Content-Length Content-Range),
    allow_credentials: true,
    max_age: 86_400
  ]

  def init(opts), do: opts

  def call(conn, _opts), do: Corsica.call(conn, corsica_opts())

  # The origins never change after boot, so the parsed options are cached on
  # first use rather than rebuilt on every request.
  defp corsica_opts do
    case :persistent_term.get(__MODULE__, nil) do
      nil ->
        opts = Corsica.init(Keyword.put(@corsica_opts, :origins, origins()))
        :persistent_term.put(__MODULE__, opts)
        opts

      opts ->
        opts
    end
  end

  # See https://hexdocs.pm/corsica/Corsica.html#module-origins
  defp origins do
    :cadet
    |> Application.get_env(CadetWeb.Endpoint, [])
    |> Keyword.get(:cors_endpoints, "*")
  end
end
