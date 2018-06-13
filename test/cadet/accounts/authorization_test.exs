defmodule Cadet.Accounts.AuthorizationTest do
  use Cadet.ChangesetCase, async: true

  alias Cadet.Accounts.Authorization

  valid_changesets Authorization do
    %{provider: :nusnet_id, uid: "some@gmail.com", token: "sometoken", user_id: 2}
  end

  invalid_changesets Authorization do
    %{provider: :nusnet_id, uid: "some@gmail.com", user_id: 2}
    %{provider: :email, token: "sometoken", user_id: 2}
    %{provider: :facebook, utoken: "sometoken", user_id: 2}
  end
end
