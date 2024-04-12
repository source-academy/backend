defmodule Cadet.SharedPrograms.SharedProgram do
  @moduledoc """
  Contains methods for storing frontend programs to database with uuid.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "shared_programs" do
    field(:data, :map)
    field(:uuid, Ecto.UUID)

    timestamps()
  end

  @doc false
  def changeset(shared_program, attrs) do
    shared_program
    |> cast(attrs, [:data])
    |> generate_uuid_if_nil()
    |> validate_required([:uuid])
  end

  defp generate_uuid_if_nil(changeset) do
    if get_change(changeset, :uuid) do
      changeset
    else
      put_change(changeset, :uuid, Ecto.UUID.generate())
    end
  end

  defimpl String.Chars, for: Cadet.SharedPrograms.SharedProgram do
    def to_string(%Cadet.SharedPrograms.SharedProgram{uuid: uuid}) do
      "SharedProgram with UUID: #{uuid}"
    end
  end
end
