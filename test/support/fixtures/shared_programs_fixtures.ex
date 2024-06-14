defmodule Cadet.SharedProgramsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Cadet.SharedPrograms` context.
  """

  @doc """
  Generate a shared_program.
  """
  def shared_program_fixture(attrs \\ %{}) do
    {:ok, shared_program} =
      attrs
      |> Enum.into(%{
        data: %{},
        uuid: "7488a646-e31f-11e4-aace-600308960662"
      })
      |> Cadet.SharedPrograms.create_shared_program()

    shared_program
  end
end
