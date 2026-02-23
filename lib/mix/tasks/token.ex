defmodule Mix.Tasks.Cadet.Token do
  @moduledoc """
  Helper to generate access_token to ease development.

  Usage: `mix cadet.token <role>`

  where <role> in #{inspect(Enum.filter(Cadet.Accounts.Role.__valid_values__(), &is_binary/1))}

  For example: `mix cadet.token student`

  Caveat emptor!!! The list of roles here is generated at compile-time.
  To get the most up-to-date list, please recompile by running `mix`
  """

  @shortdoc "Generates access_token JWT for a given user role"

  use Mix.Task

  import Ecto.Query
  import IO.ANSI

  alias Cadet.Accounts.{CourseRegistration, Role, User}
  alias Cadet.Courses.Course
  alias Cadet.Auth.Guardian
  alias Cadet.Repo

  @env_allow_mock ~w(dev)a

  def run(args) do
    # Suppress Ecto SQL logs
    Logger.configure(level: :error)

    # Required for Ecto to work properly, from Mix.Ecto
    Mix.Task.run("app.start")

    roles = Enum.filter(Role.__valid_values__(), &is_binary/1)
    role = List.first(args)

    if role in roles do
      user = test_user(role)

      {:ok, access_token, _} =
        Guardian.encode_and_sign(user, %{}, token_type: "access", ttl: {1, :day})

      {:ok, refresh_token, _} =
        Guardian.encode_and_sign(user, %{}, token_type: "refresh", ttl: {1, :week})

      IO.puts("#{bright()}Test user id:#{reset()} #{cyan()}#{user.id}#{reset()}")
      IO.puts("#{bright()}Test user:#{reset()}")
      IO.puts("#{cyan()}#{inspect(user, pretty: true)}#{reset()}")
      IO.puts("#{bright()}refresh_token:#{reset()}")
      IO.puts("#{refresh_token}")
      IO.puts("#{bright()}JWT:#{reset()}")
      IO.puts("Bearer #{access_token}")
    else
      IO.puts("Invalid arguments provided.")
      IO.puts("For help, run `mix help cadet.token`")
    end
  end

  @spec test_user(atom() | String.t()) :: User.t()
  defp test_user(role) when is_atom(role) or is_binary(role) do
    if Cadet.Env.env() in @env_allow_mock do
      user =
        User
        |> join(:inner, [u], cr in "course_registrations", on: u.id == cr.user_id)
        |> where([u, cr], cr.role == ^role)
        |> first
        |> Repo.one()

      if user do
        user
      else
        role_capitalized = String.capitalize("#{role}")

        course = case Repo.one(Course) do
          course -> course
          nil ->
            %Course{}
            |> Course.changeset(%{title: "Test Course", source_chapter: 1, source_variant: "default"})
            |> Repo.insert!()
        end

        new_user =
          %User{}
          |> User.changeset(%{name: "Test#{role_capitalized}", username: "test_#{role}", provider: "test"})
          |> Repo.insert!()

        %CourseRegistration{}
        |> CourseRegistration.changeset(%{user_id: new_user.id, course_id: course.id, role: role})
        |> Repo.insert!()

        new_user
      end
    end
  end
end
