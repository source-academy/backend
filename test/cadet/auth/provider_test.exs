defmodule Cadet.Auth.ProviderTest do
  @moduledoc """
  Some of the test values in this file are specified in config/test.exs.
  """

  use ExUnit.Case, async: true

  alias Cadet.Auth.Provider

  test "with valid provider" do
    assert {:ok, _} = Provider.authorise("test", "student_code", nil, nil)
    assert {:ok, _} = Provider.get_name("test", "student_token")
    assert {:ok, _} = Provider.get_role("test", "student_token")
  end

  test "with invalid provider" do
    assert {:error, :other, "Invalid or nonexistent provider config"} =
             Provider.authorise("3452345", "student_code", nil, nil)

    assert {:error, :other, "Invalid or nonexistent provider config"} =
             Provider.get_name("32523453", "student_token")

    assert {:error, :other, "Invalid or nonexistent provider config"} =
             Provider.get_role("tes0938456720t", "student_token")
  end
end
