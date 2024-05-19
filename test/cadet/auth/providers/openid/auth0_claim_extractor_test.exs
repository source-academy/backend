defmodule Cadet.Auth.Providers.Auth0ClaimExtractorTest do
  use ExUnit.Case, async: true

  alias Cadet.Auth.Providers.Auth0ClaimExtractor, as: Testee

  @username "hello@world.com"

  test "test verified email" do
    claims = %{
      "email" => @username,
      "email_verified" => true,
      "name" => "name name",
      "https://source-academy.github.io/role" => "admin"
    }

    assert Testee.get_username(claims, "") == @username
    assert Testee.get_name(claims, "") == "name name"

    assert Testee.get_token_type() == "id_token"
  end

  test "test non-verified email" do
    claims = %{"email" => @username, "email_verified" => false}

    assert is_nil(Testee.get_username(claims, ""))
  end
end
