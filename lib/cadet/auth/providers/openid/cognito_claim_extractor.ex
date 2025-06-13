defmodule Cadet.Auth.Providers.CognitoClaimExtractor do
  @moduledoc """
  Extracts fields from Cognito JWTs.
  """

  @behaviour Cadet.Auth.Providers.OpenID.ClaimExtractor

  def get_username(claims, _access_token) do
    claims["username"]
  end

  def get_name(claims, _access_token) do
    claims["username"]
  end

  def get_token_type, do: "access_token"
end
