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

  @doc """
  Returns whether hardened mode is enabled. Under hardened mode, course
  creation is restricted to super admins.
  """
  @spec hardened_mode? :: boolean()
  def hardened_mode? do
    Application.get_env(:cadet, :hardened_mode, false)
  end
end
