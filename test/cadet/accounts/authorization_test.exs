defmodule Cadet.Accounts.AuthorizationTest do
  use Cadet.ChangesetCase, async: true

  alias Cadet.Accounts.Authorization

  valid_changesets Authorization do
    %{provider: :nusnet_id, uid: "E012345", user_id: 2}
  end

  invalid_changesets Authorization do
    %{provider: :nusnet_id, uid: "", user_id: 2}
    %{provider: :facebook, uid: "E012345", user_id: :unknown}
    %{provider: :email, user_id: 2}
  end
end
