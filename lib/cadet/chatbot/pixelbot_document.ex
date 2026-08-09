defmodule Cadet.Chatbot.PixelbotDocument do
  @moduledoc """
  A course document available to the pixelbot RAG pipeline. `s3_key` is intentionally
  independent of the document's category and title, so renaming either never requires
  moving the underlying S3 object (see Cadet.Chatbot.DocumentUploader).
  """
  use Cadet, :model

  alias Cadet.Courses.Course
  alias Cadet.Chatbot.PixelbotCategory

  @type t :: %__MODULE__{
          course_id: integer(),
          category_id: integer(),
          doc_key: String.t(),
          title: String.t(),
          description: String.t(),
          release_date: Date.t() | nil,
          s3_key: String.t(),
          filename: String.t(),
          media_type: String.t()
        }

  schema "pixelbot_documents" do
    field(:doc_key, :string)
    field(:title, :string)
    field(:description, :string, default: "")
    field(:release_date, :date)
    field(:s3_key, :string)
    field(:filename, :string)
    field(:media_type, :string)

    belongs_to(:course, Course)
    belongs_to(:category, PixelbotCategory)

    timestamps()
  end

  @required_fields ~w(course_id category_id doc_key title s3_key filename media_type)a
  @optional_fields ~w(description release_date)a

  def changeset(document, params) do
    params = normalize_nil_description(params)

    document
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:course_id)
    |> foreign_key_constraint(:category_id)
    |> unique_constraint([:course_id, :doc_key])
    |> unique_constraint(:s3_key)
  end

  defp normalize_nil_description(%{description: nil} = params),
    do: Map.put(params, :description, "")

  defp normalize_nil_description(%{"description" => nil} = params),
    do: Map.put(params, "description", "")

  defp normalize_nil_description(params), do: params
end
