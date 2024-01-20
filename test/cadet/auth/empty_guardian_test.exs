defmodule Cadet.Auth.EmptyGuardianTest do
  use ExUnit.Case
  alias Cadet.Auth.EmptyGuardian

  describe "config/1" do
    test "returns default value for allowed_drift" do
      assert EmptyGuardian.config(:allowed_drift) == 10_000
    end

    test "returns nil for other keys" do
      assert EmptyGuardian.config(:other_key) == nil
    end
  end

  describe "config/2" do
    test "returns default value for allowed_drift regardless of second argument" do
      assert EmptyGuardian.config(:allowed_drift, :default) == 10_000
    end

    test "returns second argument for other keys" do
      assert EmptyGuardian.config(:other_key, :default) == :default
    end
  end
end
