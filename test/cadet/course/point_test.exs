defmodule Cadet.Course.PointTest do
  use Cadet.DataCase

  alias Cadet.Course.Point

  @valid_changeset_params [
    %{reason: "DG XP Week 4", amount: 200} 
  ]

  @invalid_changeset_params %{
    "empty reason" => %{reason: "", amount: 100},
    "zero amount" => %{reason: "Some reason", amount: 0},
    "negative amount" => %{reason: "Some reason", amount: -100}
  }

  test "valid changeset" do
    @valid_changeset_params
    |> Enum.map(&Point.changeset(%Point{}, &1))
    |> Enum.each(&assert(&1.valid?()))
  end

  test "invalid changesets" do
    for {reason, param} <- @invalid_changeset_params do
      changeset = Point.changeset(%Point{}, param)
      refute(changeset.valid?(), reason)
    end
  end
end
