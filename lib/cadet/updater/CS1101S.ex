defmodule Cadet.Updater.CS1101S do
  @moduledoc """
  Pulls content from the remote cs1101s repository into a local one.
  """

  @remote_repo Dotenv.load().values["01S_REPOSITORY"]
  @key_file Dotenv.load().values["01S_RSA_KEY"]
  @local_name "cs1101s"

  def clone() do
    git("clone", [@remote_repo, @local_name])
  end

  def fetch() do
    git("fetch")
  end

  def pull() do
    git("pull")
  end

  def git(cmd, args \\ [])

  def git("clone", args) do
    System.cmd("git", ["clone"] ++ args, env: [{"GIT_SSH_COMMAND", "ssh -i #{@key_file}"}])
  end

  def git(cmd, args) do
    System.cmd(
      "git",
      ["-C", @local_name] ++ [cmd] ++ args,
      env: [{"GIT_SSH_COMMAND", "ssh -i #{@key_file}"}]
    )
  end
end
