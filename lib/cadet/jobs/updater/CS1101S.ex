defmodule Cadet.Updater.CS1101S do
  @moduledoc """
  Pulls content from the remote cs1101s repository into a local one.
  """

  @key_file :cadet |> Application.fetch_env!(:updater) |> Keyword.get(:cs1101s_rsa_key)
  @local_name if Mix.env() != :test, do: "cs1101s", else: "test/fixtures/local_repo"
  @remote_repo (if Mix.env() != :test do
                  :cadet
                  |> Application.fetch_env!(:updater)
                  |> Keyword.get(:cs1101s_repository)
                else
                  "test/fixtures/remote_repo"
                end)

  require Logger

  @doc "Check whether repository is already cloned"
  @spec repo_cloned? :: boolean()
  def repo_cloned? do
    case File.ls(@local_name) do
      {:ok, files} -> Enum.any?(files, &(&1 == ".git"))
      _ -> false
    end
  end

  @spec clone :: no_return()
  def clone do
    Logger.info("Cloning CS1101S: Started")

    if repo_cloned?() do
      Logger.info("CS1101S is already cloned.")
    else
      git("clone", ["--recursive", @remote_repo, @local_name])
    end

    Logger.info("Cloning CS1101S: Done")
  end

  def update do
    Logger.info("Updating CS1101S...")
    git("pull", ["--recurse-submodules", "origin", "master"])
    git("submodule", ["update", "--remote", "--recursive"])
  end

  defp git(cmd, args) do
    extra_args = if cmd == "clone", do: [], else: ["-C", @local_name]

    {out, exit} =
      System.cmd(
        "git",
        extra_args ++ [cmd] ++ args,
        env: [{"GIT_SSH_COMMAND", "ssh -i #{@key_file}"}],
        stderr_to_stdout: true
      )

    if exit != 0 do
      error_message = "git #{cmd} #{inspect(args)} errored with exit code #{exit}\n#{out}"
      Logger.error(error_message)
      Sentry.capture_message(error_message)
    else
      Logger.info("git #{cmd} #{inspect(args)} succeeded")
      Logger.debug(fn -> "\n#{out}" end)
    end

    {out, exit}
  end
end
