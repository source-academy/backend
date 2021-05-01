defmodule Cadet.Auth.Providers.CognitoClaimExtractor do
  @moduledoc """
  Extracts fields from Cognito JWTs.
  """

  @behaviour Cadet.Auth.Providers.OpenID.ClaimExtractor

  def get_username(claims) do
    claims["username"]
  end

  def get_name(claims) do
    claims["username"]
  end

  def get_role(claims) do
    case claims["cognito:groups"] do
      [head | _] when is_atom(head) -> head
      ["admin" | _] -> :admin
      ["staff" | _] -> :staff
      nil -> nil
      _ -> :student
    end
  end

  def get_token_type, do: "access_token"
end
