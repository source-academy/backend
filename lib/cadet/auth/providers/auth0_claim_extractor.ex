defmodule Cadet.Auth.Providers.Auth0ClaimExtractor do
  @moduledoc """
  Extracts fields from Auth0 JWTs.

  Note: an Auth0 Rule that adds the role to the ID token is required. E.g.:

  ```
  function (user, context, callback) {
    if (context.idToken && user.app_metadata && user.app_metadata.role) {
      context.idToken['https://source-academy.github.io/role'] = user.app_metadata.role;
    }
    callback(null, user, context);
  }
  ```
  """

  @behaviour Cadet.Auth.Providers.OpenID.ClaimExtractor

  def get_username(claims) do
    if claims["email_verified"] do
      claims["email"]
    else
      nil
    end
  end

  def get_name(claims), do: claims["name"]

  def get_role(claims), do: claims["https://source-academy.github.io/role"]

  def get_token_type, do: "id_token"
end
