defmodule Cadet.Course.Material do
  @moduledoc """
  Material represents a hierarchical file system structure
  """
  use Cadet, :model
  use Arc.Ecto.Schema

  alias Cadet.Accounts.User
  alias Cadet.Course.Material
  alias Cadet.Course.Upload

  schema "materials" do
    field(:name, :string)
    field(:description, :string)
    field(:file, Upload.Type)

    belongs_to(:parent, Material)
    belongs_to(:uploader, User)

    timestamps()
  end

  @required_fields ~w(name)a
  @optional_fields ~w(description)a
  @optional_file_fields ~w(file)a

  def folder_changeset(material, attrs \\ %{}) do
    material
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_changeset
  end

  def changeset(material, attrs \\ %{}) do
    material
    |> cast_attachments(attrs, @optional_file_fields)
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_changeset
  end

  defp validate_changeset(changeset) do
    changeset
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:parent_id)
    |> foreign_key_constraint(:uploader_id)
  end
end
