defmodule Cadet.AssertHelper do
  @moduledoc """
  Contains some general assertion helpers for tests.
  """

  import ExUnit.Assertions, only: [assert: 1]

  def assert_submaps_eq(expected, actual, fields) do
    assert length(expected) == length(actual)

    Enum.map(Enum.zip([expected, actual]), fn {e, a} -> assert_submap_eq(e, a, fields) end)
  end

  def assert_submap_eq(expected, actual, fields) do
    assert Map.take(expected, fields) == Map.take(actual, fields)
  end
end
