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
  Returns whether this instance is the group leader.

  The group leader is the cadet instance that does certain tasks that must only
  be done by one instance e.g. running Cadet.Autograder.GradingJob.
  """
  @spec leader? :: boolean
  def leader? do
    # TODO: allow this to be specified using AWS instance tags
    not is_nil(System.get_env("LEADER"))
  end
end
