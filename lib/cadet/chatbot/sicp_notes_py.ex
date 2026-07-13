defmodule Cadet.Chatbot.SicpNotesPy do
  @moduledoc """
  Module to store Python textbook section summaries for the chatbot.

  Add Python summaries here using the same section keys as `Cadet.Chatbot.SicpNotes`,
  for example:

      @summary_1_1_1 \"\"\"
      1.1.1 Expressions
      ...
      \"\"\"

      @notes %{
        "1.1.1" => @summary_1_1_1
      }
  """

  @notes %{
           # Add Python textbook summaries here.
           # Example:
           # "1.1.1" => @summary_1_1_1
         }

  @spec get_summary(String.t()) :: String.t() | nil
  def get_summary(section) do
    Map.get(@notes, section)
  end
end
