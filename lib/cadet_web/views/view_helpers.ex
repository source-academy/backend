defmodule CadetWeb.ViewHelpers do
  @moduledoc """
  Helper functions shared throughout views
  """

  def format_datetime(datetime) do
    Timex.format!(DateTime.truncate(datetime, :millisecond), "{ISO:Extended}")
  end
end
