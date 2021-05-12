defmodule Cadet.Env do
  @moduledoc """
  Contains helpers to retrieve certain application-wide runtime configuration.
  """

  @doc """
  Returns the current environment.
  """
  @spec env :: atom()
  def env do
    Application.get_env(:cadet, :environment)
  end
end
