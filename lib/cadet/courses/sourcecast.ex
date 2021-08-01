defmodule Cadet.Courses.Sourcecast do
  @moduledoc """
  Sourcecast stores audio files and deltas for playback
  """
  use Cadet, :model
  use Arc.Ecto.Schema

  alias Cadet.Accounts.User
  alias Cadet.Courses.{Course, SourcecastUpload}

  schema "sourcecasts" do
    field(:title, :string)
    field(:playbackData, :string)
    field(:description, :string)
    field(:uid, :string)
    field(:audio, SourcecastUpload.Type)

    belongs_to(:uploader, User)
    belongs_to(:course, Course)

    timestamps()
  end

  @required_fields ~w(title playbackData uid)a
  @optional_fields ~w(description course_id)a
  @required_file_fields ~w(audio)a
  @regex Regex.compile!("^[a-zA-Z0-9_-]*$")

  def changeset(sourcecast, attrs \\ %{}) do
    sourcecast
    |> cast_attachments(attrs, @required_file_fields)
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> gen_uid_if_empty
    |> validate_changeset
  end

  defp gen_uid_if_empty(changeset) do
    case get_change(changeset, :uid) do
      # note: Ecto casts "" to nil by default, so this covers "" too
      nil -> put_change(changeset, :uid, Ecto.UUID.generate())
      _ -> changeset
    end
  end

  defp validate_changeset(changeset) do
    changeset
    |> validate_required(@required_fields ++ @required_file_fields)
    |> validate_format(:uid, @regex)
    |> foreign_key_constraint(:uploader_id)
    |> foreign_key_constraint(:course_id)
  end
end
