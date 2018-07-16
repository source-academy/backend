defmodule Cadet.Updater.CS1101S do
  @moduledoc """
  Pulls content from the remote cs1101s repository into a local one.
  """

  @remote_repo (if Mix.env() != :test do
                  Dotenv.load().values["01S_REPOSITORY"]
                else
                  "test/remote_repo"
                end)
  @local_name if Mix.env() != :test, do: "cs1101s", else: "test/local_repo"
  @key_file Dotenv.load().values["01S_RSA_KEY"]

  require Logger

  @spec clone :: no_return()
  def clone do
    Logger.info("Cloning CS1101S: Started")
    git("clone", [@remote_repo, @local_name])
    Logger.info("Cloning CS1101S: Done")
  end

  def update do
    Logger.info("Updating CS1101S...")
    git("pull")
  end

  defp git(cmd, args \\ [])

  defp git("clone", args) do
    {out, exit} =
      System.cmd(
        "git",
        ["clone"] ++ args,
        env: [{"GIT_SSH_COMMAND", "ssh -i #{@key_file}"}],
        stderr_to_stdout: true
      )

    Logger.debug(fn ->
      "git clone exited with #{exit}: #{out}"
    end)

    {out, exit}
  end

  defp git(cmd, args) do
    {out, exit} =
      System.cmd(
        "git",
        ["-C", @local_name] ++ [cmd] ++ args,
        env: [{"GIT_SSH_COMMAND", "ssh -i #{@key_file}"}],
        stderr_to_stdout: true
      )

    Logger.debug(fn ->
      "git #{cmd} #{inspect(args)} exited with #{exit}: #{out}"
    end)

    {out, exit}
  end
end
