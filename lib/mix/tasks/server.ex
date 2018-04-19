defmodule Mix.Tasks.Cadet.Server do
  @moduledoc """
    Run the Cadet server.
    Currently it is equivalent with `phx.server`
  """
  use Mix.Task

  def run(args) do
    try do
      Dotenv.load!()
    rescue
      e in RuntimeError -> e
    end
    :ok = Mix.Tasks.Phx.Server.run(args)
  end
end
