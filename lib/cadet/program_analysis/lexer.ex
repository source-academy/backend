defmodule Cadet.ProgramAnalysis.Lexer do
  @moduledoc """
  Provides functions to lexically analyse program strings
  """

  def count_tokens(program) do
    case lex(program) do
      {:ok, tokens} ->
        Enum.count(tokens)

      {:error, _} ->
        0
    end
  end

  defp lex(str) do
    case :source_lexer.string(to_charlist(str)) do
      {:ok, tokens, _} ->
        {:ok, tokens}

      {:error, reason, _} ->
        {:error, reason}
    end
  end
end
