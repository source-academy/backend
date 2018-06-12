defmodule Cadet.Accounts.Form.RegistrationTest do
  use Cadet.ChangesetCase, async: true

  alias Cadet.Accounts.Form.Registration

  valid_changesets Registration do
    %{
      name: "happy",
      nusnet_id: "e853820",
      email: "some@gmail.com",
      password: "mypassword",
      password_confirmation: "mypassword"
    }
  end

  invalid_changesets Registration do
    %{
      email: "some@gmail.com",
      password: "mypassword",
      password_confirmation: "mypassword"
    }

    %{
      first_name: "happy",
      email: "some@gmail.com",
      password: "mypassword",
      password_confirmation: "doesnotmatch"
    }

    %{
      first_name: "happy",
      email: "somegmail.com",
      password: "mypassword",
      password_confirmation: "mypassword"
    }

    %{
      first_name: "happy",
      email: "some@gmail.com",
      password: "passwor",
      password_confirmation: "passwor"
    }
  end
end
