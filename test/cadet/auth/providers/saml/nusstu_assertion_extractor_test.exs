defmodule Cadet.Auth.Providers.NusstuAssertionExtractorTest do
  use ExUnit.Case, async: true

  alias Cadet.Auth.Providers.NusstuAssertionExtractor, as: Testee

  @username "JohnT"
  @assertion %{attributes: %{"samaccountname" => @username}}

  test "success" do
    assert @username == Testee.get_username(@assertion)
    assert @username == Testee.get_name(@assertion)
  end
end
