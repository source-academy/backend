defmodule Cadet.Updater.CS1101STest do
  @moduledoc """
  This module creates a mock remote repository at test/remote_repo, and uses it
  as the target repository for Cadet.Updater.CS1101S.
  """

  @remote_repo "test/remote_repo"
  @local_repo "test/local_repo"

  use Cadet.DataCase
  use ExUnit.Case, async: false

  alias Cadet.Updater.CS1101S

  setup_all do
    {_, 0} = System.cmd("mkdir", [@remote_repo])
    {_, 0} = git_from(@remote_repo, "init", ["--bare"])
    # git pull fails on an empty --bare repo, so need to push something there first
    git_add_file("dummy_setup_all", @remote_repo)
    on_exit(fn -> clean_dirs([@local_repo, @remote_repo]) end)
    :ok
  end

  test "Clone is ok" do
    assert :ok == CS1101S.clone()
    assert File.exists?(@local_repo)
    {_, 0} = clean_dirs([@local_repo])
  end

  test "With update" do
    CS1101S.clone()
    assert {_, 0} = CS1101S.update()
    assert File.exists?(Path.join(@local_repo, "dummy_setup_all"))
  end
end
