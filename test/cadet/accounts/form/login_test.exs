defmodule Cadet.Accounts.LoginTest do
  use Cadet.ChangesetCase, async: true

  alias Cadet.Accounts.Form.Login

  valid_changesets Login do
    %{email: "some@gmail.com", password: "somepassword"}
  end

  invalid_changesets Login do
    %{email: "", password: "somepassword"}
    %{email: "some@gmail.com", password: ""}
  end
end
