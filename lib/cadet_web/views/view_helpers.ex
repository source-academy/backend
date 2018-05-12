defmodule CadetWeb.ViewHelpers do
  @moduledoc """
  Helper functions shared throughout views
  """
  use Phoenix.HTML

  def logged_in?(conn) do
    conn.assigns[:current_user] != nil
  end

  def is_roles?(conn, roles) do
    if logged_in?(conn) do
      conn.assigns[:current_user].role in roles
    else
      false
    end
  end
end
