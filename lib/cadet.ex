defmodule Cadet do
  @moduledoc """
  Cadet keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  def model do
    quote do
      use Ecto.Schema

      import Ecto.Changeset
      import Cadet.ModelHelper
    end
  end

  def context do
    quote do
      alias Cadet.Repo

      import Ecto.Changeset
      import Cadet.ContextHelper
    end
  end

  def display do
    quote do
      import Cadet.DisplayHelper
    end
  end

  def remote_assets do
    quote do
      use Arc.Definition
      use Arc.Ecto.Definition
    end
  end

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
        raise "invalid arguments when using Cadet contexts"
    end
  end
end
