defmodule Cadet.Course.Material do
  @moduledoc """
  Material represents a hierarchical file system structure
  """
  use Cadet, :model
  use Arc.Ecto.Schema

  alias Cadet.Accounts.User
  alias Cadet.Course.{Category, MaterialUpload}

  schema "materials" do
    field(:title, :string)
    field(:description, :string)
    field(:file, MaterialUpload.Type)

    belongs_to(:uploader, User)
    belongs_to(:category, Category)

    timestamps()
  end

  @required_fields ~w(title)a
  @optional_fields ~w(description)a
  @required_file_fields ~w(file)a

  def changeset(material, attrs \\ %{}) do
    material
    |> cast_attachments(attrs, @required_file_fields)
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_changeset
  end

  defp validate_changeset(changeset) do
    changeset
    |> validate_required(@required_fields ++ @required_file_fields)
    |> foreign_key_constraint(:uploader_id)
    |> foreign_key_constraint(:category_id)
  end
end
