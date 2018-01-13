defmodule Cadet.Accounts do
  @moduledoc """
  Accounts context contains domain logic for User management and Authentication
  """
  use Cadet, :context

  alias Comeonin.Pbkdf2

  alias Cadet.Accounts.User
  alias Cadet.Accounts.Query
  alias Cadet.Accounts.Authorization
  alias Cadet.Accounts.Form.Registration

  @doc """
  Register new User entity using E-mail and Password
  authentication.
  """
  def register(attrs = %{}, role) do
    changeset = Registration.changeset(%Registration{}, attrs)

    if changeset.valid?() do
      registration = apply_changes(changeset)

      Repo.transaction(fn ->
        attrs_with_role = Map.put(attrs, :role, role)
        {:ok, user} = create_user(attrs_with_role)

        {:ok, _} =
          create_authorization(
            %{
              provider: :email,
              uid: registration.email,
              token: Pbkdf2.hashpwsalt(registration.password)
            },
            user
          )

        user
      end)
    else
      {:error, changeset}
    end
  end

  @doc """
  Creates Authorization entity with specified attributes.
  """
  def create_authorization(attrs = %{}, user = %User{}) do
    %Authorization{}
    |> Authorization.changeset(attrs)
    |> put_assoc(:user, user)
    |> Repo.insert()
  end

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
    token = get_token(:email, email) || get_random_token()

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

  @doc """
  Associate a password to an existing `%User{}`
  The user will be able to authenticate using any of the e-mail
  and the password.
  """
  def set_password(user = %User{}, password) do
    token = Pbkdf2.hashpwsalt(password)

    Repo.transaction(fn ->
      authorizations = Repo.all(Query.user_emails(user.id))

      for email <- authorizations do
        email
        |> change(%{token: token})
        |> Repo.update!()
      end
    end)
  end

  @doc """
  Sign in using given e-mail and password combination
  """
  def sign_in(email, password) do
    auth = Repo.one(Query.email(email))

    cond do
      auth == nil ->
        {:error, :not_found}

      not Pbkdf2.checkpw(password, auth.token) ->
        {:error, :invalid_password}

      true ->
        auth = Repo.preload(auth, :user)
        {:ok, auth.user}
    end
  end

  defp get_token(provider, uid) do
    auth = Repo.get_by(Authorization, provider: provider, uid: uid)

    if auth == nil do
      nil
    else
      auth.token
    end
  end

  defp get_random_token() do
    length = 64

    :crypto.strong_rand_bytes(length)
    |> Base.url_encode64()
    |> binary_part(0, length)
  end
end
