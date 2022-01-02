defmodule Cadet.Auth.Providers.MITClaimExtractor do
  @moduledoc """
  Extracts fields from MIT OIDC JWTs.
  """

  @behaviour Cadet.Auth.Providers.OpenID.ClaimExtractor

  def get_username(_claims, access_token), do: Map.get(get_userinfo(access_token), "email")

  def get_name(_claims, access_token), do: Map.get(get_userinfo(access_token), "name")

  def get_token_type, do: "access_token"

  defp get_userinfo(token) do
    headers = [{"Authorization", "Bearer #{token}"}]
    options = [timeout: 10_000, recv_timeout: 10_000]

    case HTTPoison.get("https://oidc.mit.edu/userinfo", headers, options) do
      {:ok, %{body: body, status_code: 200}} ->
        {:ok, Jason.decode!(body)}

      {:ok, %{status_code: status}} ->
        {:error, :upstream, "Status code #{status} from MIT OIDC server"}
    end
  end
end
