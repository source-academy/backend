defmodule Cadet.Chatbot.RagChunk do
  @moduledoc """
  A searchable text chunk from an ingested RAG document.
  """
  use Cadet, :model

  alias Cadet.Chatbot.RagDocument
  alias Cadet.Courses.Course

  schema "rag_chunks" do
    field(:language, :string)
    field(:chunk_index, :integer)
    field(:content, :string)
    field(:token_count, :integer)
    field(:metadata, :map, default: %{})

    belongs_to(:rag_document, RagDocument)
    belongs_to(:course, Course)

    timestamps()
  end

  @required_fields ~w(rag_document_id course_id language chunk_index content)a
  @optional_fields ~w(token_count metadata)a

  def changeset(chunk, attrs) do
    chunk
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:language, ["python"])
    |> foreign_key_constraint(:rag_document_id,
      name: :rag_chunks_rag_document_id_course_id_fkey
    )
    |> foreign_key_constraint(:course_id)
  end
end
