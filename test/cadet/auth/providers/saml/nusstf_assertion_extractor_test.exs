defmodule Cadet.Auth.Providers.NusstfAssertionExtractorTest do
  use ExUnit.Case, async: true

  alias Cadet.Auth.Providers.NusstfAssertionExtractor, as: Testee

  @username "JohnT"
  @name "John Tan"
  @assertion %{attributes: %{"SamAccountName" => @username, "DisplayName" => @name}}

  test "success" do
    assert @username == Testee.get_username(@assertion)
    assert @name == Testee.get_name(@assertion)
  end
end
