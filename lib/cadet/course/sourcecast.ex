defmodule Cadet.Course.Sourcecast do
  @moduledoc """
  Sourcecast stores audio files and deltas for playback
  """
  use Cadet, :model
  use Arc.Ecto.Schema

  alias Cadet.Accounts.User
  alias Cadet.Course.Upload

  schema "sourcecasts" do
    field(:title, :string)
    field(:playbackData, :string)
    field(:description, :string)
    field(:audio, Upload.Type)

    belongs_to(:uploader, User)

    timestamps()
  end

  @required_fields ~w(title playbackData)a
  @optional_fields ~w(description)a
  @required_file_fields ~w(audio)a

  def changeset(sourcecast, attrs \\ %{}) do
    sourcecast
    |> cast_attachments(attrs, @required_file_fields)
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_changeset
  end

  defp validate_changeset(changeset) do
    changeset
    |> validate_required(@required_fields ++ @required_file_fields)
    |> foreign_key_constraint(:uploader_id)
  end
end
