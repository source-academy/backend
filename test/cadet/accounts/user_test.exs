defmodule Cadet.Accounts.UserTest do
  use Cadet.ChangesetCase, async: true

  alias Cadet.Accounts.User

  valid_changesets User do
    %{first_name: "happy people", role: :admin}
    %{first_name: "happy", last_name: "people", role: :student}
  end

  invalid_changesets User do
    %{last_name: "people", role: :student}
    %{first_name: "happy", last_name: "people", role: :avenger}
  end
end
