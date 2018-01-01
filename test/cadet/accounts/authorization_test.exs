defmodule Cadet.Accounts.AuthorizationTest do
  use Cadet.DataCase

  alias Cadet.Accounts.Authorization

  @valid_changeset_params [
    %{provider: :email, uid: "some@gmail.com", token: "sometoken", user_id: 2}
  ]

  @invalid_changeset_params %{
    "empty token" => %{provider: :email, uid: "some@gmail.com", user_id: 2},
    "empty uid" => %{provider: :email, token: "sometoken", user_id: 2},
    "invalid provider" => %{provider: :facebook, utoken: "sometoken", user_id: 2}
  }

  test "valid changeset" do
    @valid_changeset_params
    |> Enum.map(&Authorization.changeset(%Authorization{}, &1))
    |> Enum.each(&assert(&1.valid?()))
  end

  test "invalid changesets" do
    for {reason, param} <- @invalid_changeset_params do
      changeset = Authorization.changeset(%Authorization{}, param)
      refute(changeset.valid?(), reason)
    end
  end
end
