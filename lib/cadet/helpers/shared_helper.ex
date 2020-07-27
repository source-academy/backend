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

  @doc """
  Snake-casifies string keys.

  Meant for use when accepting a JSON map from the frontend, where keys are
  usually camel-case.
  """
  def snake_casify_string_keys(map = %{}) do
    for {key, val} <- map,
        into: %{},
        do: {if(is_binary(key), do: Recase.to_snake(key), else: key), val}
  end

  @doc """
  Snake-casifies string keys, recursively.

  Meant for use when accepting a JSON map from the frontend, where keys are
  usually camel-case.
  """
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

  @doc """
  Stringifies atom keys, recursively.

  Intended for use in a model, when receiving changes to be passed to
  Ecto.Changeset.cast, but the changes need to be pre-processed, since the
  changes could be keyed with either atoms or strings.
  """
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

  @doc """
  Camel-casifies atom keys and converts them to strings.

  Meant for use when sending an Elixir map, which usually has snake-case keys,
  to the frontend.
  """
  def camel_casify_atom_keys(map = %{}) do
    for {key, val} <- map,
        into: %{},
        do: {if(is_atom(key), do: key |> Atom.to_string() |> Recase.to_camel(), else: key), val}
  end

  @doc """
  Sends an error to Sentry. The error can be anything.
  """
  def send_sentry_error(error) do
    {_, stacktrace} = Process.info(self(), :current_stacktrace)
    # drop 2 elements off the stacktrace: the frame of Process.info, and the
    # frame of this function
    stacktrace = stacktrace |> Enum.drop(2)

    error = Exception.normalize(:error, error, stacktrace)

    Sentry.capture_exception(error, stacktrace: stacktrace)
  end
end
