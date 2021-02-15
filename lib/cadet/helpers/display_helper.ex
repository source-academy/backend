defmodule Cadet.DisplayHelper do
  @moduledoc """
  Contains utility functions that may be used for modules that need to be displayed to the user.
  """
  import Ecto.Changeset

  def put_display_order(changeset, collection) do
    if Enum.empty?(collection) do
      change(changeset, %{display_order: 1})
    else
      last = Enum.max_by(collection, & &1.display_order)
      change(changeset, %{display_order: last.display_order + 1})
    end
  end

  @spec full_error_messages(%Ecto.Changeset{}) :: String.t()
  def full_error_messages(changeset = %Ecto.Changeset{}) do
    changeset
    |> traverse_errors(&process_error/1)
    |> format_message()
  end

  def full_error_messages(changeset), do: changeset

  defp process_error({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(
        acc,
        "%{#{key}}",
        if(is_list(value), do: Enum.join(value, ","), else: inspect(value))
      )
    end)
  end

  defp format_message(errors = %{}) do
    errors
    |> Enum.map(fn {k, v} ->
      message =
        v
        |> Enum.map(fn
          %{} = sub -> "{#{format_message(sub)}}"
          str -> str
        end)
        |> Enum.join("; ")

      "#{k} #{message}"
    end)
    |> Enum.join("\n")
  end

  def create_invalid_changeset_with_error(key, message) do
    add_error(%Ecto.Changeset{}, key, message)
  end
end
