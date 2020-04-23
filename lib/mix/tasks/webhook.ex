defmodule Mix.Tasks.Cadet.Webhook do
  @moduledoc """
    Initilise local module files by
      cloning the GitHub repository

    Before execution, the modules directory should not exist,
      otherwise cloning would fail and an error is raised

    The default modules github repo can be changed by
      modifying the arg of Git.clone/1 (repo git address)
      and File.rename/2 (folder name and location)
  """

  use Mix.Task

  def run(_args) do
    {:ok, _repo} = Git.clone("https://github.com/source-academy/modules.git")
    File.rename("modules", "priv/modules")
  end
end
