defmodule Cadet.Auth.GuardianTest do
  use Cadet.DataCase

  import Cadet.TestHelper
  alias Cadet.Auth.Guardian

  test "token subject is user id" do
    user = insert(:user)
    assert Guardian.subject_for_token(user, nil) == {:ok, to_string(user.id)}
  end

  test "get user from claims" do
    user = insert(:user)

    good_claims = %{
      "sub" => to_string(user.id)
    }

    bad_claims = %{
      "sub" => "2000"
    }

    assert Guardian.resource_from_claims(good_claims) ==
             {:ok, remove_preload(user, :latest_viewed_course)}

    assert Guardian.resource_from_claims(bad_claims) == {:error, :not_found}
  end
end
