defmodule Cadet.Auth.Guardian do
  @moduledoc """
  Guardian implementation module
  """
  use Guardian, otp_app: :cadet

  alias Cadet.Accounts
  alias Guardian.DB

  def subject_for_token(user, _claims) do
    {:ok, to_string(user.id)}
  end

  def resource_from_claims(claims) do
    user = Accounts.get_user(claims["sub"])

    if user == nil do
      {:error, :not_found}
    else
      {:ok, user}
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

  # TODO: Uncomment when there is an update to guardian_db > v1.1.0
  # (when git commit ef024b6 is merged)
  # def on_refresh({old_token, old_claims}, {new_token, new_claims}, _options) do
  #   with {:ok, _} <- DB.on_refresh({old_token, old_claims}, {new_token, new_claims}) do
  #     {:ok, {old_token, old_claims}, {new_token, new_claims}}
  #   end
  # end

  def on_revoke(claims, token, _options) do
    with {:ok, _} <- DB.on_revoke(claims, token) do
      {:ok, claims}
    end
  end
end
