defmodule Cadet.SharedProgramsTest do
  use Cadet.DataCase

  alias Cadet.SharedPrograms

  describe "shared_programs" do
    alias Cadet.SharedPrograms.SharedProgram

    import Cadet.SharedProgramsFixtures

    @invalid_attrs %{data: nil, uuid: nil}

    test "list_shared_programs/0 returns all shared_programs" do
      shared_program = shared_program_fixture()
      assert SharedPrograms.list_shared_programs() == [shared_program]
    end

    test "get_shared_program!/1 returns the shared_program with given id" do
      shared_program = shared_program_fixture()
      assert SharedPrograms.get_shared_program!(shared_program.id) == shared_program
    end

    test "create_shared_program/1 with valid data creates a shared_program" do
      valid_attrs = %{data: %{}, uuid: "7488a646-e31f-11e4-aace-600308960662"}

      assert {:ok, %SharedProgram{} = shared_program} = SharedPrograms.create_shared_program(valid_attrs)
      assert shared_program.data == %{}
      assert shared_program.uuid == "7488a646-e31f-11e4-aace-600308960662"
    end

    test "create_shared_program/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = SharedPrograms.create_shared_program(@invalid_attrs)
    end

    test "update_shared_program/2 with valid data updates the shared_program" do
      shared_program = shared_program_fixture()
      update_attrs = %{data: %{}, uuid: "7488a646-e31f-11e4-aace-600308960668"}

      assert {:ok, %SharedProgram{} = shared_program} = SharedPrograms.update_shared_program(shared_program, update_attrs)
      assert shared_program.data == %{}
      assert shared_program.uuid == "7488a646-e31f-11e4-aace-600308960668"
    end

    test "update_shared_program/2 with invalid data returns error changeset" do
      shared_program = shared_program_fixture()
      assert {:error, %Ecto.Changeset{}} = SharedPrograms.update_shared_program(shared_program, @invalid_attrs)
      assert shared_program == SharedPrograms.get_shared_program!(shared_program.id)
    end

    test "delete_shared_program/1 deletes the shared_program" do
      shared_program = shared_program_fixture()
      assert {:ok, %SharedProgram{}} = SharedPrograms.delete_shared_program(shared_program)
      assert_raise Ecto.NoResultsError, fn -> SharedPrograms.get_shared_program!(shared_program.id) end
    end

    test "change_shared_program/1 returns a shared_program changeset" do
      shared_program = shared_program_fixture()
      assert %Ecto.Changeset{} = SharedPrograms.change_shared_program(shared_program)
    end
  end
end
