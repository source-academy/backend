defmodule Cadet.Parser.Parser do
  @moduledoc """
  Provides functions to lexically analyse program strings 
  """

  require Logger

  def lex(program) do
    case parse(program) do
      {:ok, tokens} ->
        count_tokens(tokens)

      {:error, reason} ->
        Logger.debug(inspect(reason))
        []
    end
  end

  defp count_tokens(tokens) do
    Enum.reduce(tokens, 0, fn _curr, acc -> acc + 1 end)
  end

  defp parse(str) do
    case :source_lexer.string(to_charlist(str)) do
      {:ok, tokens, _} ->
        {:ok, tokens}

      {:error, reason, _} ->
        {:error, reason}
    end
  end
end
