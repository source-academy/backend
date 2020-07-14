defmodule Cadet.SharedHelper do
  @moduledoc """
  Contains utility functions that may be commonly used across Cadet and CadetWeb..
  """

  defmacro is_ecto_id(id) do
    quote do
      is_integer(unquote(id)) or is_binary(unquote(id))
    end
  end

  def snake_casify_keys(map = %{}) do
    for {key, val} <- map, into: %{}, do: {Recase.to_snake(key), val}
  end
end
