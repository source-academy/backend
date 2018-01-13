defmodule Cadet.Auth.Guardian do
  use Guardian, otp_app: :cadet

  alias Cadet.Accounts

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
end
