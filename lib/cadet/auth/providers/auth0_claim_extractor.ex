defmodule Cadet.Auth.Providers.Auth0ClaimExtractor do
  @moduledoc """
  Extracts fields from Auth0 JWTs.
  """

  @behaviour Cadet.Auth.Providers.OpenID.ClaimExtractor

  def get_username(claims, _id_token) do
    if claims["email_verified"] do
      claims["email"]
    else
      nil
    end
  end

  def get_name(claims, _id_token), do: claims["name"]

  def get_token_type, do: "id_token"
end
