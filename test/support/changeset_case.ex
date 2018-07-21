defmodule Cadet.ChangesetCase do
  @moduledoc """
  This module defines helper method(s) that is useful to test changeset/2 of
  an Ecto schema.

  This module provides `assert_changeset`, `assert_changeset_db`, `generate_changeset`
  ```
  """

  defmacro __using__(opt) do
    if opt[:entity] do
      quote do
        use Cadet.DataCase

        @spec assert_changeset(map(), :valid | :invalid, atom()) :: any()
        defp assert_changeset(params, valid_or_invalid, function_name \\ :changeset) do
          changeset = generate_changeset(params, function_name)

          tester =
            case valid_or_invalid do
              :valid -> &assert/2
              :invalid -> &refute/2
            end

          tester.(changeset.valid?, inspect(changeset, pretty: true))
        end

        @spec assert_changeset_db(map(), :valid | :invalid, atom()) :: any()
        defp assert_changeset_db(params, valid_or_invalid, function_name \\ :changeset) do
          result =
            params
            |> generate_changeset(function_name)
            |> Cadet.Repo.insert()

          expected =
            case valid_or_invalid do
              :valid -> :ok
              :invalid -> :error
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
