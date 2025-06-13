defmodule Cadet.Auth.ProviderTest do
  @moduledoc """
  Some of the test values in this file are specified in config/test.exs.
  """

  use ExUnit.Case, async: true

  alias Cadet.Auth.Provider

  test "with valid provider" do
    assert {:ok, _} = Provider.authorise(%{provider_instance: "test", code: "student_code"})

    assert {:ok, _} = Provider.get_name("test", "student_token")
  end

  test "with invalid provider" do
    assert {:error, :other, "Invalid or nonexistent provider config"} =
             Provider.authorise(%{provider_instance: "3452345", code: "student_code"})

    assert {:error, :other, "Invalid or nonexistent provider config"} =
             Provider.get_name("32523453", "student_token")
  end
end
