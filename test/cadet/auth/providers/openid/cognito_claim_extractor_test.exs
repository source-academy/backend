defmodule Cadet.Auth.Providers.CognitoClaimExtractorTest do
  use ExUnit.Case, async: true

  alias Cadet.Auth.Providers.CognitoClaimExtractor, as: Testee

  @username "adofjihid"
  @role :staff
  @claims %{"username" => @username, "cognito:groups" => [Atom.to_string(@role)]}

  test "test" do
    assert @username == Testee.get_username(@claims, "")
    assert @username == Testee.get_name(@claims, "")

    assert Testee.get_token_type() == "access_token"
  end
end
