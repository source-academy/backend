defmodule Cadet.Test.ChangesetHelper do
  @moduledoc """
  This module defines helper method(s) that is useful to test changeset/2 of
  an Ecto schema.

  This module provides `test_changeset`, `test_changeset_db`, `generate_changeset`
  ```
  """

  defmacro __using__(opt) do
    if opt[:entity] do
      quote do
        @spec test_changeset(map(), :assert | :refute, atom()) :: any()
        defp test_changeset(params, assert_or_refute \\ :assert, function_name \\ :changeset) do
          changeset = generate_changeset(params, function_name)

          tester =
            case assert_or_refute do
              :assert -> &assert/2
              :refute -> &refute/2
            end

          tester.(changeset.valid?, inspect(changeset, pretty: true))
        end

        @spec test_changeset_db(map(), :assert | :refute, atom()) :: any()
        defp test_changeset_db(params, assert_or_refute \\ :assert, function_name \\ :changeset) do
          result =
            params
            |> generate_changeset(function_name)
            |> Cadet.Repo.insert()

          expected =
            case assert_or_refute do
              :assert -> :ok
              :refute -> :error
            end

          {status, _} = result

          assert(status == expected, inspect(result, pretty: true))
        end

        @spec generate_changeset(map(), atom()) :: Ecto.Changeset.t()
        defp generate_changeset(params, function_name \\ :changeset) do
          apply(unquote(opt[:entity]), function_name, [struct(unquote(opt[:entity])), params])
        end
      end
    else
      raise "invalid arguments -- please supply :entity option"
    end
  end
end
