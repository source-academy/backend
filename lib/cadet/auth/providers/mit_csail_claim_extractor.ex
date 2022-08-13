defmodule Cadet.Auth.Providers.MITCSAILClaimExtractor do
  @moduledoc """
  Extracts fields from MIT CSAIL OIDC JWTs.
  """

  @behaviour Cadet.Auth.Providers.OpenID.ClaimExtractor

  def get_username(_claims, access_token), do: get_userinfo(access_token, "email")

  def get_name(_claims, access_token), do: get_userinfo(access_token, "name")

  def get_token_type, do: "access_token"

  defp get_userinfo(token, key) do
    headers = [{"Authorization", "Bearer #{token}"}]
    options = [timeout: 10_000, recv_timeout: 10_000]

    case HTTPoison.get("https://oidc.csail.mit.edu/userinfo", headers, options) do
      {:ok, %{body: body, status_code: 200}} ->
        body |> Jason.decode!() |> Map.get(key)

      {:ok, _} ->
        nil
    end
  end
end
