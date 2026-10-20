# Vector RAG Textbook Ingestion

This guide explains how to add or replace a Markdown textbook/course note source in the backend vector RAG pipeline used by the legacy chat endpoint.

The preferred source is the deployed Markdown textbook URL. The local Python helper can still read a local file for offline development or emergency manual ingestion, but local files should not be treated as canonical once the deployed URL is available.

## Production Deployment

Production deployment runs textbook ingestion automatically after migrations:

```bash
"$BASEDIR/bin/cadet" rpc Cadet.Release.migrate
"$BASEDIR/bin/cadet" rpc Cadet.Release.ingest_sicpy_textbook
```

The deploy script calls both commands in `deployment/init.sh`. The ingestion task is checksum-aware, so repeated deploys do not duplicate rows when the deployed Markdown content has not changed.

Set these environment values in the deployed runtime config:

```bash
SICPY_MARKDOWN_URL="https://sicp.sourceacademy.org/sicpy.md"
SICPY_COURSE_ID="<COURSE_ID>"
SICPY_TITLE="SICP Python"
SICPY_SOURCE_FILENAME="sicpy.md"
SICPY_EMBEDDING_RETRIES="3"
OPENAI_API_KEY="<OPENAI_API_KEY>"
```

`SICPY_COURSE_ID` must match the real production course id. Chat retrieval filters by `course_id`, so ingesting under the wrong course id makes the textbook chunks invisible to that course.

The release task uses:

- `Cadet.Release.ingest_sicpy_textbook`
- `Cadet.Chatbot.TextbookIngestion`
- the app's configured embedding model, defaulting to `text-embedding-3-small`
- the app's configured OpenAI embedding API URL
- `SICPY_CHUNK_SIZE`, defaulting to `3600` characters
- `SICPY_CHUNK_OVERLAP`, defaulting to `600` characters

## Local Quick Commands

Run everything from the backend root:

```bash
cd /Users/isha/backend
```

One-time local setup:

```bash
python3 -m venv .venv
.venv/bin/pip install -r priv/rag/requirements.txt
mix ecto.migrate
```

Set the deployed textbook URL:

```bash
export SICPY_MARKDOWN_URL="https://sicp.sourceacademy.org/sicpy.md"
```

Dry-run chunking:

```bash
.venv/bin/python priv/rag/ingest_text.py "$SICPY_MARKDOWN_URL" --course-id 1 --title "SICP Python" --source-filename sicpy.md --dry-run
```

Dry-run chunking and write all chunks locally:

```bash
.venv/bin/python priv/rag/ingest_text.py "$SICPY_MARKDOWN_URL" --course-id 1 --title "SICP Python" --source-filename sicpy.md --dry-run --dry-run-output priv/rag/chunk_outputs/sicpy_chunks.jsonl
```

Manual local ingestion, if needed:

```bash
DATABASE_URL="postgres://postgres:postgres@localhost:5432/cadet_dev" .venv/bin/python priv/rag/ingest_text.py "$SICPY_MARKDOWN_URL" --course-id 1 --title "SICP Python" --source-filename sicpy.md
```

For local development, the Python ingestion script automatically reads the OpenAI API key from `config/dev.secrets.exs` under `config :openai`. You do not need to export `OPENAI_API_KEY` unless you want to override the dev secrets value.

Turn on vector RAG for chat:

```bash
export VECTOR_RAG_ENABLED=true
```

Optional local retrieval debugging:

```bash
export VECTOR_RAG_DEBUG=true
```

Optional similarity threshold override. The default is `0.3`; set an empty value to disable threshold filtering.

```bash
export VECTOR_RAG_MIN_SIMILARITY=0.3
```

When enabled, the backend logs the retrieved top chunks for each chat request, including similarity score, section, section title, source filename, and a short content preview.

Change `--course-id 1` to the real course id. If the deployed URL does not end in a useful filename, pass `--source-filename sicpy.md` so chunk metadata remains readable.

The flow is:

1. Point the ingestion task at the deployed Markdown URL.
2. Run a local dry-run when validating a new textbook source or parser change.
3. Deploy migrations.
4. Run `Cadet.Release.ingest_sicpy_textbook` to populate `rag_documents` and `rag_chunks`.
5. Enable vector retrieval for chat.

## What This Pipeline Does

The production release task reads Markdown from the deployed HTTP(S) URL. The local Python script can also read a local file for dry-runs and emergency manual ingestion. Both paths detect headings such as:

```md
# 1 Building Abstractions with Functions
## 1.1 The Elements of Programming
### 1.1.1 Expressions
```

It then chunks text inside those heading sections and stores metadata for each chunk. Production uses the Elixir splitter in `Cadet.Chatbot.TextbookIngestion`; the local Python helper uses LangChain's `RecursiveCharacterTextSplitter` for dry-runs and manual ingestion.

```json
{
  "source_filename": "sicpy.md",
  "section": "1.1.1",
  "section_title": "Expressions",
  "heading_path": [
    "1 Building Abstractions with Functions",
    "1.1 The Elements of Programming",
    "1.1.1 Expressions"
  ]
}
```

During chat, the backend embeds the student's question plus the visible paragraph context, retrieves the top relevant chunks from `rag_chunks`, and injects those chunks into the prompt. The default retrieval count is 8 chunks. When the answer relies on retrieved notes with section metadata, the model should end with a short reference such as:

```text
Read more: Section 1.1.1.
```

The model is instructed not to invent section numbers when no relevant section metadata is available.

## Prerequisites

Postgres must have pgvector installed.

The backend migration creates the extension and tables:

```bash
mix ecto.migrate
```

The relevant migration is:

```text
priv/repo/migrations/20260711000000_create_vector_rag_tables.exs
```

It creates:

- `rag_documents`
- `rag_chunks`
- `rag_chunks.embedding vector(1536)`

The ingestion paths assume the embedding model produces 1536-dimensional vectors. The default is:

```text
text-embedding-3-small
```

## 1. Choose The Markdown Source

Prefer the deployed Markdown textbook URL:

```bash
export SICPY_MARKDOWN_URL="https://sicp.sourceacademy.org/sicpy.md"
```

If the URL path does not end with a meaningful filename, add a metadata filename override when running ingestion:

```bash
--source-filename sicpy.md
```

For offline development only, a local file can still be used:

```text
path/to/<FILE>.md
```

The source filename is stored in metadata and helps debugging later.

## 2. Install Python Ingestion Dependencies

Use the repo-local virtualenv:

```bash
python3 -m venv .venv
.venv/bin/pip install -r priv/rag/requirements.txt
```

If `.venv` already exists and dependencies are installed, you can skip this step.

## 3. Dry-Run Chunking Before Writing To DB

Always dry-run first.

```bash
.venv/bin/python priv/rag/ingest_text.py "$SICPY_MARKDOWN_URL" \
  --course-id <COURSE_ID> \
  --title "<DISPLAY TITLE>" \
  --dry-run
```

Example:

```bash
.venv/bin/python priv/rag/ingest_text.py "$SICPY_MARKDOWN_URL" \
  --course-id 1 \
  --title "SICP Python" \
  --dry-run \
  --dry-run-output priv/rag/chunk_outputs/sicpy_chunks.jsonl
```

The dry-run prints:

- total chunks
- section bucket count
- numbered section count
- first 20 section chunk counts
- previews of the first chunks

It also writes every chunk to `priv/rag/chunk_outputs/sicpy_chunks.jsonl` when `--dry-run-output` is provided. This JSONL file is for local inspection only; it is not needed by ingestion.

Each line looks like:

```json
{"chunk_index":0,"section":"1.1.1","section_title":"Expressions","heading_path":["1 Building Abstractions with Functions","1.1 The Elements of Programming","1.1.1 Expressions"],"source_filename":"sicpy.md","content":"..."}
```

For `sicpy.md`, the dry-run result was:

```text
Chunks: 542
Section buckets: 131
Numbered sections: 130
```

Some `unsectioned` chunks are acceptable if the file has front matter such as forewords, prefaces, references, or appendices without numbered section headings.

## 4. Check Section Detection

Before ingesting, inspect the dry-run output.

Good signs:

- section numbers look like `1`, `1.1`, `1.1.1`
- major sections have reasonable chunk counts
- previews start around expected Markdown headings
- only front matter is `unsectioned`

Bad signs:

- most chunks are `unsectioned`
- section numbers are missing
- one section has hundreds of chunks unexpectedly
- chunks split headings from their section body

If section detection looks wrong for the production release task, adjust the heading format or update the parser in:

```text
lib/cadet/chatbot/textbook_ingestion.ex
```

If section detection looks wrong for Python dry-runs or manual Python ingestion, update the parser in:

```text
priv/rag/ingest_text.py
```

The parser expects Markdown headings with numeric titles:

```md
# 1 Chapter Title
## 1.1 Section Title
### 1.1.1 Subsection Title
```

## 5. Set Database URL and OpenAI Key

Manual Python ingestion needs database access and an OpenAI API key.

For the default local Docker/Postgres setup, pass the database URL inline:

```bash
DATABASE_URL="postgres://postgres:postgres@localhost:5432/cadet_dev" .venv/bin/python priv/rag/ingest_text.py "$SICPY_MARKDOWN_URL" --course-id 1 --title "SICP Python" --source-filename sicpy.md
```

The OpenAI API key is loaded in this order:

1. `OPENAI_API_KEY` environment variable, if set.
2. `--openai-api-key`, if passed.
3. `config/dev.secrets.exs`, from `config :openai, api_key: "..."`.

So for local development, adding the key to `config/dev.secrets.exs` is enough. Do not commit API keys or database credentials.

Optional for manual Python ingestion:

```bash
export VECTOR_RAG_EMBEDDING_MODEL="text-embedding-3-small"
```

## 6. Run Ingestion

In production, ingestion runs through the release task after migrations:

```bash
"$BASEDIR/bin/cadet" rpc Cadet.Release.ingest_sicpy_textbook
```

For manual local ingestion after dry-run looks correct:


```bash
.venv/bin/python priv/rag/ingest_text.py "$SICPY_MARKDOWN_URL" \
  --course-id <COURSE_ID> \
  --title "<DISPLAY TITLE>" \
  --source-filename sicpy.md
```

Example:

```bash
.venv/bin/python priv/rag/ingest_text.py "$SICPY_MARKDOWN_URL" \
  --course-id 1 \
  --title "SICP Python" \
  --source-filename sicpy.md
```

This writes:

- one row to `rag_documents`
- many rows to `rag_chunks`
- one embedding per chunk
- section metadata into `rag_chunks.metadata`

Both ingestion paths are checksum-aware. If the same source content has already been ingested for the same course, ingestion exits instead of duplicating rows.

## 7. Verify DB Rows

Check that the document is ready:

```sql
SELECT id, course_id, title, language, status, embedding_model, metadata
FROM rag_documents
ORDER BY inserted_at DESC
LIMIT 5;
```

Check chunks and section metadata:

```sql
SELECT
  chunk_index,
  metadata->>'section' AS section,
  metadata->>'section_title' AS section_title,
  LEFT(content, 120) AS preview
FROM rag_chunks
WHERE course_id = <COURSE_ID>
  AND language = 'python'
ORDER BY chunk_index
LIMIT 20;
```

Check chunk count:

```sql
SELECT COUNT(*)
FROM rag_chunks
WHERE course_id = <COURSE_ID>
  AND language = 'python';
```

## 8. Enable Retrieval In Chat

Vector retrieval is disabled by default so existing chat behavior is preserved.

Enable it with:

```bash
export VECTOR_RAG_ENABLED=true
```

For local debugging, also enable retrieval logs:

```bash
export VECTOR_RAG_DEBUG=true
```

Then start the backend normally. Or run both inline:

```bash
VECTOR_RAG_ENABLED=true VECTOR_RAG_DEBUG=true mix phx.server
```

The legacy chat endpoint stays the same:

```http
POST /v2/chats/message
```

Frontend should send:

```json
{
  "message": "How do recursive functions return?",
  "section": "1.1.4",
  "initialContext": "Visible paragraph text from the frontend"
}
```

The frontend does not send a language field. The backend is Python-only for this chatbot and always retrieves Python chunks internally.

## 9. How Retrieval Works At Runtime

When a student sends a chat message:

1. The backend combines the student message and visible paragraph context.
2. `OpenAIEmbeddings` embeds that combined query.
3. `VectorRetriever` compares the query vector against `rag_chunks.embedding`.
4. pgvector returns the top matching chunks using cosine distance.
5. `PromptBuilder` injects those chunks into the system prompt.
6. If chunk metadata includes a section, the prompt includes it:

If `VECTOR_RAG_DEBUG=true`, the backend also logs the selected chunks:

```text
Vector RAG retrieved 8 chunk(s) for course_id=1 language=python limit=8
1. id=123 chunk_index=42 similarity=0.8123 section=1.1.1 section_title="Expressions" title="SICP Python" source="sicpy.md" preview="..."
```

```text
(1b.1) SICP Python
Section: 1.1.1 Expressions
...
```

The model can then answer and, when it relies on retrieved notes with section metadata, add:

```text
Read more: Section 1.1.1.
```

## 10. Updating An Existing Textbook

If the file content changes, its checksum changes. Running ingestion again creates a new `rag_documents` row and new chunks.

If you want to replace old chunks for the same course, delete the old document row:

```sql
DELETE FROM rag_documents
WHERE id = <OLD_DOCUMENT_ID>;
```

Chunks are deleted automatically through `ON DELETE CASCADE`.

Then rerun ingestion.

## 11. Common Problems

`CREATE EXTENSION vector` fails:

Postgres does not have pgvector installed. Install pgvector for the local or deployment Postgres instance.

`DATABASE_URL or --database-url is required`:

Set `DATABASE_URL` or pass `--database-url`.

`OPENAI_API_KEY` error:

Add `api_key: "..."` under `config :openai` in `config/dev.secrets.exs`, set `OPENAI_API_KEY`, or pass `--openai-api-key`. The environment variable wins if more than one is present.

Dry-run works but ingestion fails on vector dimensions:

The embedding model likely does not produce 1536-dimensional vectors. Use `text-embedding-3-small`, or change the migration and database column dimension intentionally.

Chat works but no chunks appear in prompt:

Check:

- `VECTOR_RAG_ENABLED=true`
- `rag_documents.status = 'ready'`
- chunks exist for the user's `latest_viewed_course_id`
- chunks exist with internal language `python`
