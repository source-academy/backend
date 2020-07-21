defmodule Cadet.SharedHelper do
  @moduledoc """
  Contains utility functions that may be commonly used across Cadet and CadetWeb..
  """

  defmacro is_ecto_id(id) do
    quote do
      is_integer(unquote(id)) or is_binary(unquote(id))
    end
  end

  def rename_keys(map, key_map) do
    Enum.reduce(key_map, map, fn {from, to}, map ->
      if Map.has_key?(map, from) do
        {v, map} = Map.pop!(map, from)
        Map.put(map, to, v)
      else
        map
      end
    end)
  end

  def snake_casify_string_keys(map = %{}) do
    for {key, val} <- map,
        into: %{},
        do: {if(is_binary(key), do: Recase.to_snake(key), else: key), val}
  end

  def snake_casify_string_keys_recursive(map = %{}) when not is_struct(map) do
    for {key, val} <- map,
        into: %{},
        do:
          {if(is_binary(key), do: Recase.to_snake(key), else: key),
           snake_casify_string_keys_recursive(val)}
  end

  def snake_casify_string_keys_recursive(list) when is_list(list) do
    for e <- list, do: snake_casify_string_keys_recursive(e)
  end

  def snake_casify_string_keys_recursive(other), do: other

  def stringify_atom_keys_recursive(s) when is_struct(s) do
    stringify_atom_keys_recursive(Map.from_struct(s))
  end

  def stringify_atom_keys_recursive(map = %{}) do
    for {k, v} <- map,
        into: %{},
        do: {if(is_atom(k), do: Atom.to_string(k), else: k), stringify_atom_keys_recursive(v)}
  end

  def stringify_atom_keys_recursive(list) when is_list(list) do
    for e <- list, do: stringify_atom_keys_recursive(e)
  end

  def stringify_atom_keys_recursive(other), do: other
end
