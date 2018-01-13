defmodule CadetWeb.ViewHelpers do
  @moduledoc """
  Helper functions shared throughout views
  """
  use Phoenix.HTML

  def logged_in?(conn) do
    conn.assigns[:current_user] != nil
  end
end
