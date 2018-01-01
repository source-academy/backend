defmodule Cadet.Accounts.RegistrationTest do
  use Cadet.DataCase

  alias Cadet.Accounts.Registration

  @valid_changeset_params [
    %{
      first_name: "happy",
      email: "some@gmail.com",
      password: "mypassword",
      password_confirmation: "mypassword"
    }
  ]

  @invalid_changeset_params %{
    "empty first_name" => %{
      email: "some@gmail.com",
      password: "mypassword",
      password_confirmation: "mypassword"
    },
    "confirmation does not match" => %{
      first_name: "happy",
      email: "some@gmail.com",
      password: "mypassword",
      password_confirmation: "doesnotmatch"
    },
    "invalid email" => %{
      first_name: "happy",
      email: "somegmail.com",
      password: "mypassword",
      password_confirmation: "mypassword"
    },
    "password too short" => %{
      first_name: "happy",
      email: "somegmail.com",
      password: "passwor",
      password_confirmation: "passwor"
    }
  }

  test "valid changeset" do
    @valid_changeset_params
    |> Enum.map(&Registration.changeset(%Registration{}, &1))
    |> Enum.each(&assert(&1.valid?()))
  end

  test "invalid changesets" do
    for {reason, param} <- @invalid_changeset_params do
      changeset = Registration.changeset(%Registration{}, param)
      refute(changeset.valid?(), reason)
    end
  end
end
