defmodule Cadet.Env do
  @moduledoc """
  Cadet.Env just contains a function that returns the current environment
  from the configuration.
  """

  @spec env :: atom()
  def env do
    Application.get_env(:cadet, :environment)
  end
end
