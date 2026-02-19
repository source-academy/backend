defmodule Cadet.Auth.Providers.NusEntraIdClaimExtractor do
  @moduledoc """
  Extracts fields from NUS' Microsoft Entra ID JWTs.
  """

  @behaviour Cadet.Auth.Providers.OpenID.ClaimExtractor

  @dialyzer {:nowarn_function, get_username: 2}
  def get_username(claims, access_token) do
    # TODO: Remove the debug statement after confirming the claims structure
    Jason.decode!(claims) |> IO.inspect(label: "Claims in NUS Entra ID")
    get_userinfo(access_token, "samAccountName")
  end

  @dialyzer {:nowarn_function, get_name: 2}
  def get_name(claims, access_token) do
    # TODO: Remove the debug statement after confirming the claims structure
    Jason.decode!(claims) |> IO.inspect(label: "Claims in NUS Entra ID")
    get_userinfo(access_token, "displayName")
  end

  def get_token_type, do: "access_token"

  # Allowed Active Directory (AD) domains; modify as needed
  @allowed_domains ~w(student alum staff)

  defp check_allowed_domain(claims) do
    domain = Map.get(claims, "onPremisesExtensionAttributes")["extensionAttribute6"]
    domain in @allowed_domains
  end

  defp map_key_to_raw("samAccountName"), do: "onPremisesSamAccountName"
  defp map_key_to_raw(key), do: key

  defp get_userinfo(token, key) do
    Jason.decode!(token) |> IO.inspect(label: "Token in NUS Entra ID")
    headers = [{"Authorization", "Bearer #{token}"}]
    options = [timeout: 10_000, recv_timeout: 10_000]

    url =
      "https://graph.microsoft.com/v1.0/me?$select=onPremisesSamAccountName,onPremisesExtensionAttributes"

    case HTTPoison.get(url, headers, options) do
      {:ok, %{body: body, status_code: 200}} ->
        data = Jason.decode!(body)

        with true <- check_allowed_domain(data),
             mapped_key <- map_key_to_raw(key),
             value when not is_nil(value) <- Map.get(data, mapped_key) do
          value
        else
          false -> nil
          nil -> nil
        end

      {:ok, _} ->
        nil
    end
  end
end
