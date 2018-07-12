defmodule Cadet.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  @temp_repo "test/temp_repo"

  use ExUnit.CaseTemplate

  using do
    quote do
      alias Cadet.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Cadet.DataCase
      import Cadet.Factory
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Cadet.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Cadet.Repo, {:shared, self()})
    end

    :ok
  end

  @doc """
  A helper that transform changeset errors to a map of messages.

      assert {:error, changeset} = Accounts.create_user(%{password: "short"})
      assert "password is too short" in errors_on(changeset).password
      assert %{password: ["password is too short"]} = errors_on(changeset)

  """
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Enum.reduce(opts, message, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end

  @doc """
  Run a git command with `loc` as the git repository root.
  """
  def git_from(loc, cmd, opts \\ []) do
    System.cmd("git", ["-C", loc, cmd] ++ opts, stderr_to_stdout: true)
  end

  @doc """
  Push an empty file with `filename` into the given remote repository
  """
  def git_add_file(filename, remote_repo) do
    {_, 0} = git_from(".", "clone", [remote_repo, @temp_repo])
    :ok = File.touch(Path.join(@temp_repo, filename))
    {_, 0} = git_from(@temp_repo, "add", [filename])
    {_, 0} = git_from(@temp_repo, "commit", ["-m", "dummy-commit"])
    {_, 0} = git_from(@temp_repo, "push")
    :ok = clean_dirs!([@temp_repo])
  end

  @doc """
  Remove directories.
  """
  def clean_dirs!(dirs) do
    dirs
    |> Enum.each(fn dir -> File.rm_rf!(dir) end)

    :ok
  end
end
