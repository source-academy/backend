defmodule Cadet.DisplayHelperTest.TestObject do
  use Ecto.Schema

  alias Ecto.Changeset

  schema "objects" do
    has_many(:subobjects, __MODULE__, on_replace: :delete)
  end

  def changeset(object, params) do
    object
    |> Changeset.cast(params, [:id])
    |> Changeset.cast_assoc(:subobjects)
  end
end

defmodule Cadet.DisplayHelperTest do
  use ExUnit.Case

  alias Cadet.DisplayHelperTest.TestObject

  import Cadet.DisplayHelper

  describe "full_error_messages" do
    test "passes non-changeset through" do
      assert full_error_messages("aaa") == "aaa"
    end

    test "formats simple errors" do
      changeset = TestObject.changeset(%TestObject{}, %{id: "invalid"})

      assert full_error_messages(changeset) =~ "id is invalid"
    end

    test "formats nested errors" do
      changeset = TestObject.changeset(%TestObject{}, %{subobjects: [%{id: "invalid"}]})

      assert full_error_messages(changeset) == "subobjects {id is invalid}"
    end
  end
end
