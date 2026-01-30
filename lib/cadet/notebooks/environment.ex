defmodule Cadet.Notebooks.Environment do
  @moduledoc """
  The Environment entity stores environment names of Notebook cells
  """
  use Cadet, :model

  schema "environment" do
    field(:name, :string)

    timestamps()
  end

  @required_fields ~w(name)a

  def changeset(environment, attrs \\ %{}) do
    environment
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
  end
end
