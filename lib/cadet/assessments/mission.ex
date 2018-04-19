defmodule Cadet.Assessments.Mission do
  @moduledoc """
  The Mission entity stores metadata of a students' assessment
  (mission, sidequest, path, and contest).

  Question types polymorphism is embedded in the json stored in the
  questions field.
  """
  use Cadet, :model
  use Arc.Ecto.Schema

  alias Cadet.Assessments.Category
  alias Cadet.Assessments.Image
  alias Cadet.Assessments.Upload

  @type t :: %Cadet.Assessments.Mission{}

  @default_library %{
    version: 1,
    globals: [],
    externals: [],
    files: []
  }

  schema "missions" do
    field(:order, :string)
    field(:category, Category)
    field(:title, :string)
    field(:summary_short, :string)
    field(:summary_long, :string)
    field(:open_at, Timex.Ecto.DateTime)
    field(:close_at, Timex.Ecto.DateTime)
    field(:file, Upload.Type)
    field(:cover_picture, Image.Type)
    field(:max_xp, :integer)
    field(:library, :map, default: @default_library)
    field(:questions, :map)

    field(:raw_library, :string, virtual: true)
    field(:raw_questions, :string, virtual: true)
  end

  @required_fields ~w(order category title open_at close_at max_xp library)a
  @optional_fields ~w(summary_short summary_long raw_library raw_questions questions)a
  @required_file_fields ~w(file)a
  @optional_file_fields ~w(cover_picture)a

  @spec changeset(Cadet.Assessments.Mission.t, map) :: Ecto.Changeset.t
  def changeset(mission, attrs \\ %{}) do
    mission
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> cast_attachments(attrs, @required_file_fields ++ @optional_file_fields)
    |> process_json({:raw_library, :library})
    |> process_json({:raw_questions, :questions})
    |> validate_required(@required_fields ++ @required_file_fields)
    |> validate_number(:max_xp, greater_than_or_equal_to: 0)
    |> validate_open_close_date()
    |> validate_map({:library, ~w(version globals externals files)a})
    |> validate_map({:questions, ~w(type questions)a})
    |> validate_questions()
  end

  @spec validate_questions(Ecto.Changeset.t) :: Ecto.Changeset.t
  defp validate_questions(changeset = %Ecto.Changeset{}) do
    validate_change(changeset, :questions, fn :questions, questions ->
      case validate_questions({questions.type |> String.downcase |> String.to_atom, questions}) do
        {:ok} -> []
        {:error, errors} -> [questions: errors]
      end
    end)
  end

  @spec validate_questions({:mcq, map}) :: {:ok} | {:error, String.t}
  defp validate_questions({:mcq, questions}) do

  end

  @spec validate_questions({:mcq, map}) :: {:ok} | {:error, String.t}
  defp validate_questions({:programming, questions}) do

  end

  @spec process_json(Ecto.Changeset.t, {atom, atom}) :: Ecto.Changeset.t
  defp process_json(changeset, {raw_field, field}) do
    change = get_change(changeset, raw_field)
    json = change && Poison.decode!(change)
    if json do
      put_change(changeset, field, json)
    else
      changeset
    end
  end

  @spec validate_open_close_date(Ecto.Changeset.t) :: Ecto.Changeset.t
  defp validate_open_close_date(changeset) do
    validate_change(changeset, :open_at, fn :open_at, open_at ->
      if Timex.after?(open_at, get_field(changeset, :close_at)) do
        [open_at: "Open date must be earlier than close date"]
      else
        []
      end
    end)
  end

  @spec validate_map(Ecto.Changeset.t, {atom, list(atom | String.t)}) :: Ecto.Changeset.t
  defp validate_map(changeset, {field, required_keys}) do
    validate_change(changeset, field, fn(_, value) ->
      result = required_keys
               |> Enum.all?(&(Map.has_key?(value, "#{&1}")))
      if result do
        []
      else
        [{field, "#{field} must have keys #{Enum.join(required_keys, ", ")}"}]
      end
    end)
  end
end
