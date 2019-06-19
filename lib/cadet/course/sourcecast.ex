defmodule Cadet.Course.Sourcecast do
  @moduledoc """
  Sourcecast stores audio files and deltas for playback
  """
  use Cadet, :model
  use Arc.Ecto.Schema

  alias Cadet.Accounts.User
  alias Cadet.Course.Upload

  schema "sourcecasts" do
    field(:name, :string)
    field(:deltas, :string)
    field(:audio, Upload.Type)

    belongs_to(:uploader, User)

    timestamps()
  end

  @required_fields ~w(name)a
  @optional_fields ~w(deltas)a
  @optional_file_fields ~w(audio)a

  def changeset(sourcecast, attrs \\ %{}) do
    sourcecast
    |> cast_attachments(attrs, @optional_file_fields)
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_changeset
  end

  defp validate_changeset(changeset) do
    changeset
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:uploader_id)
  end
end
