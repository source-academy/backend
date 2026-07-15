defmodule Cadet.Auth.Guardian do
  @moduledoc """
  Guardian implementation module
  """
  use Guardian, otp_app: :cadet

  alias Cadet.Accounts
  alias Guardian.DB

  def subject_for_token(user, _claims) do
    {:ok,
     URI.encode_query(%{
       id: user.id,
       username: user.username,
       provider: user.provider
     })}
  end

  def resource_from_claims(claims) do
    case claims["sub"] |> URI.decode_query() |> Map.fetch("id") do
      :error ->
        {:error, :bad_request}

      {:ok, id} ->
        case user = Accounts.get_user(id) do
          nil -> {:error, :not_found}
          _ -> {:ok, user}
        end
    end
  end

  def after_encode_and_sign(resource, claims, token, _options) do
    with {:ok, _} <- DB.after_encode_and_sign(resource, claims["typ"], claims, token) do
      {:ok, token}
    end
  end

  def on_verify(claims, token, _options) do
    with {:ok, _} <- DB.on_verify(claims, token) do
      {:ok, claims}
    end
  end

  def on_refresh({old_token, old_claims}, {new_token, new_claims}, _options) do
    DB.on_refresh({old_token, old_claims}, {new_token, new_claims})
  end

  def on_revoke(claims, token, _options) do
    with {:ok, _} <- DB.on_revoke(claims, token) do
      {:ok, claims}
    end
  end
end
