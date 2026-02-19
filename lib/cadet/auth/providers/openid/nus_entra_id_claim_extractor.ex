defmodule Cadet.Auth.Providers.NusEntraIdClaimExtractor do
  @moduledoc """
  Extracts fields from NUS' Microsoft Entra ID JWTs.
  """

  @behaviour Cadet.Auth.Providers.OpenID.ClaimExtractor

  @dialyzer {:nowarn_function, get_username: 2}
  def get_username(claims, access_token) do
    get_userinfo(claims, "samAccountName")
  end

  @dialyzer {:nowarn_function, get_name: 2}
  def get_name(claims, access_token) do
    get_userinfo(claims, "displayName")
  end

  def get_token_type, do: "id_token"

  # Allowed Active Directory (AD) domains; modify as needed
  @allowed_domains ~w(student alum staff)

  defp check_allowed_domain(claims) do
    domain = Map.get(claims, "ExtensionAttribute6")
    # TODO: Remove log
    IO.inspect({:domain, domain})
    domain in @allowed_domains
  end

  defp map_key_to_raw(key), do: key

  defp get_userinfo(claims, key) do
    with true <- check_allowed_domain(claims),
          mapped_key <- map_key_to_raw(key),
          value when not is_nil(value) <- Map.get(claims, mapped_key) do
      value
    else
      false -> nil
      _ -> nil
    end
  end
end
