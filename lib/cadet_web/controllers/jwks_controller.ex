defmodule CadetWeb.JWKSController do
  use CadetWeb, :controller

  alias Guardian.Token.Jwt.SecretFetcher.SecretFetcherDefaultImpl
  alias JOSE.JWK

  # note this has to be after the Guardian aliases above, otherwise they will
  # try to alias submodules of this module
  alias Cadet.Auth.Guardian

  def index(conn, _params) do
    json(conn, %{keys: fetch_jwks()})
  end

  defp fetch_jwks do
    secret_fetcher = Guardian.config(:secret_fetcher, SecretFetcherDefaultImpl)
    {:ok, secret} = secret_fetcher.fetch_signing_secret(Guardian, [])

    {_, public_jwk} =
      secret
      |> to_jwk()
      |> JWK.to_public_map()

    [public_jwk]
  rescue
    _ -> []
  end

  # Convert the value from Guardian's configuration to a %JWK{}
  defp to_jwk(s = %JWK{}), do: s
  defp to_jwk(s) when is_binary(s), do: JWK.from_oct(s)
  defp to_jwk(s) when is_map(s), do: JWK.from_map(s)
end
