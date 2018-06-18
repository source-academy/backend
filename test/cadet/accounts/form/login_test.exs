defmodule Cadet.Accounts.LoginTest do
  use Cadet.ChangesetCase, async: true

  alias Cadet.Accounts.Form.Login

  valid_changesets Login do
    %{ivle_token: "T0K3N"}
  end

  invalid_changesets Login do
    %{ivle_token: ""}
    %{}
  end
end
