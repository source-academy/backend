defmodule Cadet.Notebooks.Cell do
  @moduledoc """
  The Cell entity stores content of a Notebook cell
  """
  use Cadet, :model

  alias Cadet.Notebooks.{Notebook, Environment}

  schema "cell" do
    field(:iscode, :boolean)
    field(:content, :string)
    field(:output, :string)
    field(:index, :integer)

    belongs_to(:notebook, Notebook)
    belongs_to(:environment, Environment)

    timestamps()
  end

  @required_fields ~w(iscode content output index notebook environment)a

  def changeset(cell, attrs \\ %{}) do
    cell
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> add_belongs_to_id_from_model([:notebook, :environment], attrs)
  end
end
