defmodule Cadet.Updater.CS1101S do
  @moduledoc """
  Pulls content from the remote cs1101s repository into a local one.
  """

  @remote_repo Dotenv.load().values["01S_REPOSITORY"]
  @key_file Dotenv.load().values["01S_RSA_KEY"]
  @local_name "cs1101s"

  require Logger

  def clone() do
    Logger.info("Cloning CS1101S: Started")
    git("clone", [@remote_repo, @local_name])
    Logger.info("Cloning CS1101S: Done")
  end

  def update() do
    Logger.info("Updating CS1101S...")
    git("fetch")
    git("pull")
  end

  def fetch() do
    git("fetch")
  end

  def pull() do
    git("pull")
  end

  defp git(cmd, args \\ [])

  defp git("clone", args) do
    System.cmd("git", ["clone"] ++ args, env: [{"GIT_SSH_COMMAND", "ssh -i #{@key_file}"}])
  end

  defp git(cmd, args) do
    System.cmd(
      "git",
      ["-C", @local_name] ++ [cmd] ++ args,
      env: [{"GIT_SSH_COMMAND", "ssh -i #{@key_file}"}]
    )
  end
end
