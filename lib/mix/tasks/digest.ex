defmodule Mix.Tasks.Cadet.Digest do
  @moduledoc """
    Build and digest frontend assets.
  """
  use Mix.Task

  def run(args) do
    try do
      Dotenv.load!()
    rescue
      e in RuntimeError -> e
    end

    Mix.Shell.IO.cmd("cd frontend && npm run build")
    :ok = Mix.Tasks.Phx.Digest.run(args)
  end
end
