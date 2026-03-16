# PR: RAG Course Assistant Chatbot — Backend

## Summary

Adds a new RAG (Retrieval-Augmented Generation) chatbot to Source Academy that answers student questions about course materials — lectures, tutorials, recitations, and past-year exams. This is a **separate chatbot** from the existing SICP textbook bot, with its own API endpoints, conversation storage, and document retrieval pipeline.

The system uses a two-pass LLM architecture:
1. **Routing pass**: GPT-4o reads a document map and selects which documents are relevant to the student's question
2. **Answer pass**: GPT-4o receives the selected PDFs as inline attachments and generates an answer with citations

---

## New Features

### 1. Two-Pass RAG Pipeline (`lib/cadet/chatbot/rag_pipeline.ex`)
- Orchestrates the full RAG flow: routing → S3 fetch → answer generation
- `process_rag_query/1` takes a user message and returns either `{:rag, prompt, pdf_attachments}` or `{:fallback}`
- Routing LLM parses document IDs from GPT-4o's JSON response, with fallback regex extraction for robustness
- Gracefully falls back when no documents are relevant or when fetches fail

### 2. Document Map (`priv/course_documents/document_map.json`)
- JSON file listing all available course documents with metadata (id, title, description, doc_type, year, week, s3_key)
- Currently contains 8 documents: 5 lecture slides and 3 midterm solution papers
- No database migration needed — the map is a static JSON file read at runtime
- `lib/cadet/chatbot/course_documents.ex` loads, queries, and strips S3 keys before sending to the LLM

### 3. S3 Document Fetching (`lib/cadet/chatbot/document_store.ex`)
- Downloads PDFs from the `pixelbot-demo-bucket` S3 bucket (us-east-1)
- Uses separate AWS credentials from the main ExAws config (different region)
- Base64-encodes PDFs for inline attachment in OpenAI multimodal messages
- Handles multiple file types (PDF, PPTX, DOCX) with correct MIME types
- Skips failed fetches gracefully with warnings

### 4. RAG-Specific Prompts (`lib/cadet/chatbot/prompt_builder.ex`)
Two new prompt functions added (existing SICP prompts untouched):
- `build_routing_prompt/1` — instructs the LLM to select up to 5 relevant document IDs from the map
- `build_rag_answer_prompt/0` — instructs the LLM to answer using only the attached PDFs, cite sources, and use Source language syntax

### 5. New API Endpoints
**Controller**: `lib/cadet_web/controllers/rag_chat_controller.ex`

| Method | Path | Description |
|--------|------|-------------|
| POST | `/v2/rag_chat/` | Initialize or resume a RAG conversation |
| POST | `/v2/rag_chat/message` | Send a message through the RAG pipeline |

- Authenticated only (uses `:auth`, `:ensure_auth`, `:rate_limit` pipelines)
- Accepts `{ "message": "..." }` — no section or visible text needed
- Returns same JSON format as existing chat endpoints: `{ conversationId, response }` or `{ conversationId, messages, maxContentSize }`

### 6. RAG Conversation Storage (`lib/cadet/chatbot/rag_conversations.ex`)
- Reuses the existing `llm_chats` table — no migration required
- Distinguishes RAG conversations from SICP conversations using the `prepend_context` JSONB field: `[{"chat_type": "rag"}]`
- Each user has exactly one RAG conversation (separate from their SICP conversation)

---

## Files Changed

### New Files
| File | Purpose |
|------|---------|
| `lib/cadet/chatbot/rag_pipeline.ex` | Two-pass RAG orchestration |
| `lib/cadet/chatbot/course_documents.ex` | JSON document map loader |
| `lib/cadet/chatbot/document_store.ex` | S3 fetch + base64 encoding |
| `lib/cadet/chatbot/rag_conversations.ex` | RAG conversation CRUD |
| `lib/cadet_web/controllers/rag_chat_controller.ex` | API endpoints |
| `lib/cadet_web/views/rag_chat_view.ex` | JSON response rendering |
| `priv/course_documents/document_map.json` | Document index (8 documents) |

### Modified Files
| File | Change |
|------|--------|
| `lib/cadet/chatbot/prompt_builder.ex` | Added `build_routing_prompt/1` and `build_rag_answer_prompt/0` |
| `lib/cadet_web/router.ex` | Added `/v2/rag_chat` route scope |
| `config/config.exs` | Added `:rag_documents` default config |
| `config/dev.secrets.exs` | Added `:rag_documents` S3 credentials |

### NOT Changed
- `lib/cadet_web/controllers/chat_controller.ex` — SICP chatbot is completely untouched
- `lib/cadet/chatbot/sicp_notes.ex` — No changes to existing SICP summaries
- No database migrations

---

## Architecture

```
Student Question
       │
       ▼
┌─────────────────┐
│  RagChatController │  POST /v2/rag_chat/message
└────────┬────────┘
         │
         ▼
┌─────────────────┐     ┌──────────────────┐
│   RagPipeline    │────▶│  CourseDocuments   │  Loads document_map.json
└────────┬────────┘     └──────────────────┘
         │
    Step 1: Routing LLM (GPT-4o)
    "Which documents are relevant?"
         │
         ▼ JSON array of doc IDs
         │
    Step 2: Fetch from S3
┌─────────────────┐
│  DocumentStore   │──── pixelbot-demo-bucket (us-east-1)
└────────┬────────┘
         │ base64-encoded PDFs
         ▼
    Step 3: Answer LLM (GPT-4o)
    System prompt + PDFs as multimodal attachments
         │
         ▼
    Response with citations
```

---

## Configuration

```elixir
# config/config.exs (defaults)
config :cadet, :rag_documents,
  bucket: "pixelbot-demo-bucket",
  region: "us-east-1"

# config/dev.secrets.exs (credentials)
config :cadet, :rag_documents,
  bucket: "pixelbot-demo-bucket",
  region: "us-east-1",
  access_key_id: "...",
  secret_access_key: "..."
```

---

## Testing

- All 944 existing tests pass with 0 failures
- `mix format` clean
- SICP chatbot functionality completely unaffected
- Manual testing confirms: routing selects correct documents, S3 fetches succeed, GPT-4o generates answers with citations
