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
  Returns whether course creation is restricted to super admins.
  """
  @spec restrict_course_creation? :: boolean()
  def restrict_course_creation? do
    Application.get_env(:cadet, :restrict_course_creation, false)
  end
end
