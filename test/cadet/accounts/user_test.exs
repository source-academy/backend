defmodule Cadet.Accounts.UserTest do
  use Cadet.DataCase

  alias Cadet.Accounts.User

  @valid_changeset_params [
    %{first_name: "happy people", role: :admin},
    %{first_name: "happy", last_name: "people", role: :student}
  ]

  @invalid_changeset_params %{
    "empty first name" => %{last_name: "people", role: :student},
    "invalid role" => %{first_name: "happy", last_name: "people", role: :avenger}
  }

  test "valid changeset" do
    @valid_changeset_params
    |> Enum.map(&User.changeset(%User{}, &1))
    |> Enum.each(&assert(&1.valid?()))
  end

  test "invalid changesets" do
    for {reason, param} <- @invalid_changeset_params do
      changeset = User.changeset(%User{}, param)
      refute(changeset.valid?(), reason)
    end
  end
end
