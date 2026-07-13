defmodule Cadet.Repo.Migrations.CreateVectorRagTables do
  use Ecto.Migration

  def up do
    execute("CREATE EXTENSION IF NOT EXISTS vector")

    execute("""
    CREATE TABLE rag_documents (
      id bigserial PRIMARY KEY,
      course_id bigint NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
      title varchar(255) NOT NULL,
      source_filename varchar(255) NOT NULL,
      checksum varchar(64) NOT NULL,
      language varchar(32) NOT NULL,
      status varchar(32) NOT NULL DEFAULT 'processing',
      embedding_model varchar(255) NOT NULL,
      metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
      inserted_at timestamp(0) without time zone NOT NULL,
      updated_at timestamp(0) without time zone NOT NULL
    )
    """)

    execute("""
    CREATE TABLE rag_chunks (
      id bigserial PRIMARY KEY,
      rag_document_id bigint NOT NULL REFERENCES rag_documents(id) ON DELETE CASCADE,
      course_id bigint NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
      language varchar(32) NOT NULL,
      chunk_index integer NOT NULL,
      content text NOT NULL,
      token_count integer,
      metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
      embedding vector(1536) NOT NULL,
      inserted_at timestamp(0) without time zone NOT NULL,
      updated_at timestamp(0) without time zone NOT NULL
    )
    """)

    create(unique_index(:rag_documents, [:course_id, :language, :checksum]))
    create(index(:rag_documents, [:course_id, :language, :status]))
    create(index(:rag_chunks, [:rag_document_id]))
    create(index(:rag_chunks, [:course_id, :language]))
  end

  def down do
    drop_if_exists(index(:rag_chunks, [:course_id, :language]))
    drop_if_exists(index(:rag_chunks, [:rag_document_id]))
    drop_if_exists(index(:rag_documents, [:course_id, :language, :status]))
    drop_if_exists(unique_index(:rag_documents, [:course_id, :language, :checksum]))

    execute("DROP TABLE IF EXISTS rag_chunks")
    execute("DROP TABLE IF EXISTS rag_documents")
  end
end
