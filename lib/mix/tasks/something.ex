defmodule Mix.Tasks.Cadet.Something do
  use Mix.Task

  alias Cadet.Chat

  def run(args) do
    username = List.first(args)
    {:ok, token} = Chat.get_token(username)
    IO.puts(token)
  end
end
