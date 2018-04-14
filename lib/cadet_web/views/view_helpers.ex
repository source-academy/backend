defmodule CadetWeb.ViewHelpers do
  @moduledoc """
  Helper functions shared throughout views
  """
  use Phoenix.HTML

  def logged_in?(conn) do
    conn.assigns[:current_user] != nil
  end

  def is_admin?(conn) do
    if logged_in?(conn) do
      conn.assigns[:current_user].role == :admin
    else
      false
    end
  end
end
