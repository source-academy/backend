defmodule Cadet.Accounts.UserTest do
  use Cadet.ChangesetCase, async: true

  alias Cadet.Accounts.User

  valid_changesets User do
    %{name: "happy people", nusnet_id: "e123456", role: :admin}
    %{name: "happy", nusnet_id: "e438492", role: :student}
  end

  invalid_changesets User do
    %{name: "people", role: :student}
    %{name: "happy", nusnet_id: "e8493201", role: :avenger}
  end
end
