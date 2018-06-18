defmodule Cadet.Accounts.UserTest do
  use Cadet.ChangesetCase, async: true

  alias Cadet.Accounts.User

  valid_changesets User do
    %{name: "happy people", role: :admin}
    %{name: "happy", role: :student}
  end

  invalid_changesets User do
    %{name: "people"}
    %{role: :avenger}
    %{name: "", role: :student}
  end
end
