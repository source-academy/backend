defmodule Cadet.Auth.Providers.NusstuAssertionExtractorTest do
  use ExUnit.Case, async: true

  alias Cadet.Auth.Providers.NusstuAssertionExtractor, as: Testee

  @username "JohnT"
  @firstname "John"
  @lastname "Tan"
  @assertion %{
    attributes: %{
      "samaccountname" => @username,
      "givenname" => @firstname,
      "surname" => @lastname
    }
  }

  test "success" do
    assert @username == Testee.get_username(@assertion)
    assert @firstname <> " " <> @lastname == Testee.get_name(@assertion)
  end
end
