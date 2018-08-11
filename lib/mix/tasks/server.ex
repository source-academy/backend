defmodule Mix.Tasks.Cadet.Server do
  @moduledoc """
    Run the Cadet server.
    Currently it is equivalent with `phx.server`
  """
  use Mix.Task

  def run(args) do
    :ok = Mix.Tasks.Phx.Server.run(args)
  end
end
