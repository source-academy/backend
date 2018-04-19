defmodule Mix.Tasks.Cadet.Server do
  @moduledoc """
    Run the Cadet server.
    Currently it is equivalent with `phx.server`
  """
  use Mix.Task

  @spec run([any]) :: no_return
  def run(args) do
    Dotenv.load!()
    :ok = Mix.Tasks.Phx.Server.run(args)
  end
end
