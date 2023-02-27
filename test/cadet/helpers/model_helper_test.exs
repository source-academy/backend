defmodule Cadet.ModelHelperTest.TestObject do
  @moduledoc """
  Test object.
  """
  use Ecto.Schema

  alias Ecto.Changeset

  schema "objects" do
    has_many(:prerequisites, __MODULE__, on_replace: :delete)
    field(:prerequisite_ids, {:array, :id}, virtual: true)
    field(:test_id, :id, virtual: true)
  end

  def changeset(object, params) do
    object
    |> Changeset.cast(params, [:id, :test_id, :prerequisite_ids])
    |> Changeset.cast_assoc(:prerequisites)
  end
end

defmodule Cadet.ModelHelperTest.TestObjectSpecialKey do
  @moduledoc """
  Test object.
  """
  # Credo false positive due to multiple modules in the file
  # credo:disable-for-next-line Credo.Check.Consistency.MultiAliasImportRequireUse
  use Ecto.Schema

  alias Ecto.Changeset

  @primary_key {:uuid, :binary_id, autogenerate: false}
  schema "special_objects" do
    has_many(:prerequisites, __MODULE__, on_replace: :delete)
    field(:prerequisite_uuids, {:array, :binary_id}, virtual: true)
    field(:test_uuid, :binary_id, virtual: true)
  end

  def changeset(object, params) do
    object
    |> Changeset.cast(params, [:uuid, :test_uuid, :prerequisite_uuids])
    |> Changeset.cast_assoc(:prerequisites)
  end
end

defmodule Cadet.ModelHelperTest do
  use ExUnit.Case, async: true

  # Credo false positive due to multiple modules in the file
  # credo:disable-for-next-line Credo.Check.Consistency.MultiAliasImportRequireUse
  alias Ecto.Changeset
  alias Cadet.ModelHelperTest.{TestObject, TestObjectSpecialKey}

  import Cadet.ModelHelper

  describe "cast_join_ids" do
    test "does nothing if no change" do
      cast_changes =
        %TestObject{id: 999}
        |> TestObject.changeset(%{})
        |> cast_join_ids(:prerequisite_ids, :prerequisites, fn my_id, id ->
          %{id: id, test_id: my_id}
        end)
        |> Changeset.get_change(:prerequisites)

      assert is_nil(cast_changes)
    end

    test "fails if both specified" do
      changeset =
        %TestObject{id: 999}
        |> TestObject.changeset(%{prerequisite_ids: [123], prerequisites: [%{id: 123}]})
        |> cast_join_ids(:prerequisite_ids, :prerequisites, fn my_id, id ->
          %{id: id, test_id: my_id}
        end)

      assert hd(changeset.errors) ==
               {:prerequisite_ids, {"cannot be specified when :prerequisites is too", []}}
    end

    test "casts ids correctly" do
      input_ids = [123, 456]

      cast_changes =
        %TestObject{id: 999}
        |> TestObject.changeset(%{prerequisite_ids: input_ids})
        |> cast_join_ids(:prerequisite_ids, :prerequisites, fn my_id, id ->
          %{id: id, test_id: my_id}
        end)
        |> Changeset.get_change(:prerequisites)
        |> Enum.map(& &1.changes)

      assert cast_changes |> Enum.map(& &1[:id]) |> Enum.sort() == input_ids

      for change <- cast_changes do
        assert change[:test_id] == 999
      end
    end

    test "casts special ids correctly" do
      my_uuid = "41938423-a7b0-41dc-9c0a-6e8803f9775b"

      input_uuids = [
        "2a5534f2-7a92-4225-90da-35fefd4caebf",
        "c2f64686-1223-4343-a8a4-3416a96134f2"
      ]

      cast_changes =
        %TestObjectSpecialKey{uuid: my_uuid}
        |> TestObjectSpecialKey.changeset(%{prerequisite_uuids: input_uuids})
        |> cast_join_ids(
          :prerequisite_uuids,
          :prerequisites,
          fn my_uuid, uuid ->
            %{uuid: uuid, test_uuid: my_uuid}
          end,
          :uuid
        )
        |> Changeset.get_change(:prerequisites)
        |> Enum.map(& &1.changes)

      assert cast_changes |> Enum.map(& &1[:uuid]) |> Enum.sort() == input_uuids

      for change <- cast_changes do
        assert change[:test_uuid] == my_uuid
      end
    end
  end
end
