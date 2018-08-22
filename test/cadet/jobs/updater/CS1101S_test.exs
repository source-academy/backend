defmodule Cadet.Updater.CS1101STest do
  @moduledoc """
  This module creates a mock remote repository at test/remote_repo, and uses it
  as the target repository for Cadet.Updater.CS1101S.
  """

  @remote_repo "test/fixtures/remote_repo"
  @local_repo "test/fixtures/local_repo"
  @temp_repo "test/fixtures/temp_repo"

  use Cadet.DataCase
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  alias Cadet.Updater.CS1101S

  setup do
    clean_dirs!([@local_repo, @remote_repo])
    :ok = File.mkdir(@remote_repo)
    {_, 0} = git_from(@remote_repo, "init", ["--bare"])
    # git pull fails on an empty --bare repo, so need to push something there first
    git_add_file("dummy_setup_all", @remote_repo)
    :ok
  end

  setup_all do
    on_exit(fn -> clean_dirs!([@local_repo, @remote_repo]) end)
  end

  test "not cloned yet" do
    :ok = clean_dirs!([@local_repo])
    refute CS1101S.repo_cloned?()
  end

  test "Clone is ok" do
    assert :ok == CS1101S.clone()
    assert File.exists?(@local_repo)
    assert CS1101S.repo_cloned?()
  end

  test "With update" do
    CS1101S.clone()
    assert {_, 0} = CS1101S.update()
    assert File.exists?(Path.join(@local_repo, "dummy_setup_all"))
  end

  test "handles error" do
    :ok = clean_dirs!([@remote_repo, @local_repo])
    assert capture_log(fn -> CS1101S.clone() end) =~ "errored with exit code"
  end

  # Run a git command with `loc` as the git repository root.
  defp git_from(loc, cmd, opts \\ []) do
    System.cmd("git", ["-C", loc, cmd] ++ opts, stderr_to_stdout: true)
  end

  # Push an empty file with `filename` into the given remote repository
  defp git_add_file(filename, remote_repo) do
    {_, 0} = git_from(".", "clone", [remote_repo, @temp_repo])
    :ok = File.touch(Path.join(@temp_repo, filename))
    {_, 0} = git_from(@temp_repo, "add", [filename])
    {_, 0} = git_from(@temp_repo, "commit", ["-m", "dummy-commit"])
    {_, 0} = git_from(@temp_repo, "push")
    :ok = clean_dirs!([@temp_repo])
  end

  # Remove directories.
  defp clean_dirs!(dirs) do
    dirs
    |> Enum.each(fn dir -> File.rm_rf!(dir) end)

    :ok
  end
end
