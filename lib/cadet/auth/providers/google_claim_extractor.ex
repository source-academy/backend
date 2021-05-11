defmodule Cadet.Auth.Providers.GoogleClaimExtractor do
  @moduledoc """
  Extracts fields from Google JWTs.
  """

  @behaviour Cadet.Auth.Providers.OpenID.ClaimExtractor

  def get_username(claims) do
    if claims["email_verified"] do
      claims["email"]
    else
      nil
    end
  end

  def get_name(_claims), do: nil

  def get_role(_claims), do: nil

  def get_token_type, do: "id_token"
end
