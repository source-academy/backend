defmodule Cadet.Auth.GuardianTest do
  use Cadet.DataCase

  import Cadet.ModelHelper
  alias Cadet.Auth.Guardian

  test "token subject is user id" do
    user = insert(:user)

    assert Guardian.subject_for_token(user, nil) ==
             {:ok,
              URI.encode_query(%{
                id: user.id,
                username: user.username,
                provider: user.provider
              })}
  end

  test "get user from claims" do
    user = insert(:user)

    good_claims = %{
      # Username and provider are only used for microservices
      # The main backend only checks the user ID
      "sub" => URI.encode_query(%{id: user.id})
    }

    bad_claims_user_not_found = %{
      "sub" => URI.encode_query(%{id: 2000})
    }

    bad_claims_bad_sub = %{
      "sub" => "bad"
    }

    assert Guardian.resource_from_claims(good_claims) ==
             {:ok, remove_preload(user, :latest_viewed_course)}

    assert Guardian.resource_from_claims(bad_claims_user_not_found) == {:error, :not_found}
    assert Guardian.resource_from_claims(bad_claims_bad_sub) == {:error, :bad_request}
  end
end
