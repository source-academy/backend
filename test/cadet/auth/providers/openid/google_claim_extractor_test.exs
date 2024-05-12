defmodule Cadet.Auth.Providers.GoogleClaimExtractorTest do
  use ExUnit.Case, async: true

  alias Cadet.Auth.Providers.GoogleClaimExtractor, as: Testee

  @username "hello@world.com"

  test "test verified email" do
    claims = %{"email" => @username, "email_verified" => true}

    assert Testee.get_username(claims, "") == @username
    assert is_nil(Testee.get_name(claims, ""))

    assert Testee.get_token_type() == "id_token"
  end

  test "test non-verified email" do
    claims = %{"email" => @username, "email_verified" => false}

    assert is_nil(Testee.get_username(claims, ""))
    assert is_nil(Testee.get_name(claims, ""))
  end
end
