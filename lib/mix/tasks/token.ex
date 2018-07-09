defmodule Mix.Tasks.Cadet.Token do
  @moduledoc """
  Helper to generate access_token to ease development.

  Usage: `mix task cadet.token <role>`

  where <role> in #{inspect(Enum.filter(Cadet.Accounts.Role.__valid_values__(), &is_binary/1))}

  For example: `mix task cadet.token student`

  Caveat emptor!!! The list of roles here is generated at compile-time.
  To get the most up-to-date list, please recompile by running `mix`
  """

  @shortdoc "Generates access_token JWT for a given user role"

  use Mix.Task

  import Mix.Ecto
  import Ecto.Query

  alias Cadet.Accounts.{Role, User}
  alias Cadet.Auth.Guardian
  alias Cadet.Repo

  @env_allow_mock ~w(dev)a

  def run(args) do
    # Suppress Ecto SQL logs
    Logger.configure(level: :error)

    # Required for Ecto to work properly, from Mix.Ecto
    ensure_started(Repo, [])

    roles = Enum.filter(Role.__valid_values__(), &is_binary/1)
    role = List.first(args)

    if Enum.count(args) == 1 and role in roles do
      {:ok, access_token, _} =
        Guardian.encode_and_sign(test_user(role), %{}, token_type: "access", ttl: {4, :weeks})

      IO.puts("Bearer #{access_token}")
    else
      IO.puts("Usage:")
      IO.puts("  mix task cadet.token <role>")
      IO.puts("where <role> in #{inspect(roles)}")
    end
  end

  @spec test_user(atom() | String.t()) :: User.t()
  defp test_user(role) when is_atom(role) or is_binary(role) do
    if Application.get_env(:cadet, :environment) in @env_allow_mock do
      user =
        User
        |> where(role: ^role)
        |> first
        |> Repo.one()

      if user do
        user
      else
        role_capitalized = String.capitalize("#{role}")

        %User{}
        |> User.changeset(%{name: "Test#{role_capitalized}", role: role})
        |> Repo.insert!()
      end
    end
  end
end
