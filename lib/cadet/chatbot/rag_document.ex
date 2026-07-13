defmodule Cadet.Chatbot.RagDocument do
  @moduledoc """
  Metadata for text documents ingested into the paragraph-chat vector index.
  """
  use Cadet, :model

  alias Cadet.Chatbot.RagChunk
  alias Cadet.Courses.Course

  schema "rag_documents" do
    field(:title, :string)
    field(:source_filename, :string)
    field(:checksum, :string)
    field(:language, :string)
    field(:status, :string, default: "processing")
    field(:embedding_model, :string)
    field(:metadata, :map, default: %{})

    belongs_to(:course, Course)
    has_many(:chunks, RagChunk)

    timestamps()
  end

  @required_fields ~w(course_id title source_filename checksum language status embedding_model)a
  @optional_fields ~w(metadata)a

  def changeset(document, attrs) do
    document
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:language, ["javascript", "python"])
    |> validate_inclusion(:status, ["processing", "ready", "failed"])
    |> foreign_key_constraint(:course_id)
    |> unique_constraint([:course_id, :language, :checksum])
  end
end
