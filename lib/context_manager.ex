defmodule ContextManager do
  @moduledoc """
    This module helps you to define context macros by providing boiletplate code.
    Usage example:

    ```
    defmodule MyModule do
      use ContextManager

      def my_context do
        import my_import_1
        import my_import_2
      end

      def my_context_2 do
        import my_import_3
        import my_import_4
      end
    end

    def MyOtherModule do
      use MyModule, :my_context
      # or
      use MyModule, [:my_context, :my_context_2]
      // other code
    end
    ```
  """
  defmacro __using__(_opt) do
    quote do
      defp apply_single(context) do
        apply(__MODULE__, context, [])
      end

      defp apply_multiple(contexts) do
        contexts
        |> Enum.filter(&is_atom/1)
        |> Enum.map(&apply_single/1)
        |> join_context_quotes
      end

      defp join_context_quotes(context_quotes) do
        Enum.reduce(
          context_quotes,
          quote do
          end,
          fn context, acc ->
            quote do
              unquote(acc)
              unquote(context)
            end
          end
        )
      end

      defmacro __using__(opt) do
        cond do
          is_atom(opt) ->
            apply_single(opt)

          is_list(opt) ->
            apply_multiple(opt)

          true ->
            raise "invalid arguments when using context"
        end
      end
    end
  end
end
