defmodule Cadet.Accounts do
  @moduledoc """
  Accounts context contains domain logic for User management and Authentication
  """
  use Cadet, :context

  alias Cadet.Accounts.User
  alias Cadet.Accounts.Authorization

  @doc """
  Creates User entity with specified attributes.
  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Get the User entity with specified primary key.
  """
  def get_user(id) do
    Repo.get(User, id)
  end

  @doc """
  Associate an e-mail address with an existing `%User{}`
  The user will be able to authenticate using the e-mail
  """
  def add_email(user = %User{}, email) do
    token = get_token(:email, email) || random_token()

    changeset =
      %Authorization{}
      |> Authorization.changeset(%{
           provider: :email,
           uid: email,
           token: token
         })
      |> put_assoc(:user, user)

    Repo.insert(changeset)
  end

  defp get_token(provider, uid) do
    auth = Repo.get_by(Authorization, provider: provider, uid: uid)

    if auth == nil do
      nil
    else
      auth.token
    end
  end

  defp random_token() do
    length = 64

    :crypto.strong_rand_bytes(length)
    |> Base.url_encode64()
    |> binary_part(0, length)
  end
end
