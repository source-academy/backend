defmodule Cadet.DeploymentHelper do
  @moduledoc """
  Contains helper functions for deployment.
  """

  defmacro __using__(_) do
    quote do
      defmacrop if_compilation(condition_block, do: do_block, else: else_block) do
        {result, _bindings} = Code.eval_quoted(condition_block)

        if result do
          do_block
        else
          else_block
        end
      end
    end
  end
end
