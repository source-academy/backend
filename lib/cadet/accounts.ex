defmodule Cadet.Accounts do
  @moduledoc """
  Accounts context contains domain logic for User management and Authentication
  """
  alias Cadet.Repo
  alias Cadet.Accounts.User

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
end
