#!/usr/bin/env python3
import argparse
import hashlib
import json
import os
import re
from datetime import datetime
from pathlib import Path

import tiktoken
from langchain_text_splitters import RecursiveCharacterTextSplitter


SUPPORTED_LANGUAGES = {"python"}
MARKDOWN_HEADING_PATTERN = re.compile(r"^(#{1,6})\s+(.+?)\s*$")
SECTION_HEADING_PATTERN = re.compile(r"^((?:\d+\.)*\d+)\s+(.+)$")
FENCED_CODE_PATTERN = re.compile(r"^\s*(```|~~~)")


def parse_args():
    parser = argparse.ArgumentParser(
        description="Chunk a course text file and insert embeddings into Cadet pgvector tables."
    )
    parser.add_argument("path", help="Path to the professor-provided .txt file")
    parser.add_argument("--course-id", required=True, type=int, help="Cadet course id")
    parser.add_argument(
        "--language",
        default="python",
        choices=sorted(SUPPORTED_LANGUAGES),
        help="Internal language tag used by chat retrieval. Defaults to python.",
    )
    parser.add_argument("--title", help="Display title for retrieved chunks")
    parser.add_argument(
        "--database-url",
        default=os.environ.get("DATABASE_URL"),
        help="Postgres connection string. Defaults to DATABASE_URL.",
    )
    parser.add_argument(
        "--embedding-model",
        default=os.environ.get("VECTOR_RAG_EMBEDDING_MODEL", "text-embedding-3-small"),
        help="Embedding model. The database migration expects 1536-dimensional vectors.",
    )
    parser.add_argument(
        "--openai-api-key",
        help="OpenAI API key. Defaults to OPENAI_API_KEY, then config/dev.secrets.exs.",
    )
    parser.add_argument(
        "--dev-secrets-path",
        default="config/dev.secrets.exs",
        help="Fallback Elixir dev secrets file used to load the OpenAI API key locally.",
    )
    parser.add_argument("--chunk-size", default=900, type=int)
    parser.add_argument("--chunk-overlap", default=150, type=int)
    parser.add_argument("--batch-size", default=64, type=int)
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Parse and chunk the file without embedding or writing to the database.",
    )
    parser.add_argument(
        "--dry-run-output",
        help="Optional JSONL path where dry-run writes every chunk and its metadata.",
    )
    return parser.parse_args()


def checksum(text):
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def now():
    return datetime.now(timezone.utc).replace(microsecond=0)


def count_tokens(text, model):
    try:
        encoding = tiktoken.encoding_for_model(model)
    except KeyError:
        encoding = tiktoken.get_encoding("cl100k_base")

    return len(encoding.encode(text))


def vector_literal(embedding):
    return "[" + ",".join(str(value) for value in embedding) + "]"


def batches(items, size):
    for index in range(0, len(items), size):
        yield items[index : index + size]


def update_heading_path(heading_path, level, title):
    updated = heading_path[: level - 1]
    updated.append(title)
    return updated


def is_document_heading(heading_title):
    return heading_title in [
        "Foreword to Structure and Interpretation of Computer Programs, 1984",
        "Prefaces to Structure and Interpretation of Computer Programs, 1996 & 1984",
        "References",
        "About the SICP JS Project",
    ]


def should_treat_as_heading(heading_match, current_section):
    if not heading_match:
        return False

    level = len(heading_match.group(1))
    heading_title = heading_match.group(2).strip()

    if SECTION_HEADING_PATTERN.match(heading_title):
        return True

    if current_section and level == 1:
        return is_document_heading(heading_title)

    return True


def split_into_heading_sections(source_text, source_filename):
    sections = []
    current_lines = []
    current_metadata = {
        "source_filename": source_filename,
        "section": None,
        "section_title": None,
        "heading_path": [],
    }
    heading_path = []
    current_section = None
    current_section_title = None
    in_fenced_code = False

    for line in source_text.splitlines():
        fence_match = FENCED_CODE_PATTERN.match(line)
        heading_match = None if in_fenced_code else MARKDOWN_HEADING_PATTERN.match(line)
        heading_match = (
            heading_match
            if should_treat_as_heading(heading_match, current_section)
            else None
        )

        if heading_match:
            if current_lines:
                sections.append(
                    {
                        "content": "\n".join(current_lines).strip(),
                        "metadata": current_metadata,
                    }
                )

            level = len(heading_match.group(1))
            heading_title = heading_match.group(2).strip()
            heading_path = update_heading_path(heading_path, level, heading_title)

            section_match = SECTION_HEADING_PATTERN.match(heading_title)
            if section_match:
                current_section = section_match.group(1)
                current_section_title = section_match.group(2).strip()
            elif level == 1:
                current_section = None
                current_section_title = None

            current_metadata = {
                "source_filename": source_filename,
                "section": current_section,
                "section_title": current_section_title,
                "heading_path": heading_path,
            }
            current_lines = [line]
        else:
            current_lines.append(line)

        if fence_match:
            in_fenced_code = not in_fenced_code

    if current_lines:
        sections.append(
            {
                "content": "\n".join(current_lines).strip(),
                "metadata": current_metadata,
            }
        )

    return [section for section in sections if section["content"]]


def build_chunks(source_text, source_filename, splitter):
    chunks = []

    for section in split_into_heading_sections(source_text, source_filename):
        content = section["content"]
        metadata = section["metadata"]

        for chunk in splitter.split_text(content):
            chunk = chunk.strip()

            if chunk and not is_heading_only_chunk(chunk):
                chunks.append({"content": chunk, "metadata": metadata})

    return chunks


def is_heading_only_chunk(chunk):
    lines = [line for line in chunk.strip().splitlines() if line.strip()]
    return len(lines) == 1 and MARKDOWN_HEADING_PATTERN.match(lines[0])


def print_dry_run(chunks):
    section_counts = {}

    for chunk in chunks:
        section = chunk["metadata"].get("section") or "unsectioned"
        section_counts[section] = section_counts.get(section, 0) + 1

    print(f"Chunks: {len(chunks)}")
    print(f"Section buckets: {len(section_counts)}")
    print(f"Numbered sections: {section_count(chunks)}")
    print("First 20 section chunk counts:")

    for section, count in list(section_counts.items())[:20]:
        print(f"  {section}: {count}")

    print("First 5 chunks:")

    for index, chunk in enumerate(chunks[:5], 1):
        metadata = chunk["metadata"]
        preview = " ".join(chunk["content"].split())[:180]
        print(
            f"  {index}. section={metadata.get('section')} "
            f"title={metadata.get('section_title')} preview={preview}"
        )


def write_dry_run_output(chunks, output_path):
    path = Path(output_path)
    path.parent.mkdir(parents=True, exist_ok=True)

    with path.open("w", encoding="utf-8") as file:
        for index, chunk in enumerate(chunks):
            metadata = chunk["metadata"]

            file.write(
                json.dumps(
                    {
                        "chunk_index": index,
                        "section": metadata.get("section"),
                        "section_title": metadata.get("section_title"),
                        "heading_path": metadata.get("heading_path"),
                        "source_filename": metadata.get("source_filename"),
                        "content": chunk["content"],
                    },
                    ensure_ascii=False,
                )
                + "\n"
            )


def section_count(chunks):
    return len(
        {
            chunk["metadata"].get("section")
            for chunk in chunks
            if chunk["metadata"].get("section")
        }
    )


def load_openai_api_key_from_dev_secrets(dev_secrets_path):
    path = Path(dev_secrets_path)

    if not path.exists():
        return None

    text = path.read_text(encoding="utf-8")
    openai_config_match = re.search(
        r"config\s+:openai\b(?P<body>.*?)(?=\nconfig\s+:|\Z)",
        text,
        flags=re.DOTALL,
    )

    if not openai_config_match:
        return None

    openai_config = openai_config_match.group("body")
    api_key_match = re.search(
        r"\b(?:api_key|openai_api_key):\s*\"([^\"]+)\"",
        openai_config,
    )

    if api_key_match:
        return api_key_match.group(1)

    return None


def ensure_openai_api_key(args):
    if os.environ.get("OPENAI_API_KEY"):
        return

    if args.openai_api_key:
        os.environ["OPENAI_API_KEY"] = args.openai_api_key
        return

    dev_secrets_api_key = load_openai_api_key_from_dev_secrets(args.dev_secrets_path)

    if dev_secrets_api_key:
        os.environ["OPENAI_API_KEY"] = dev_secrets_api_key
        return

    raise SystemExit(
        "OPENAI_API_KEY is required. Set OPENAI_API_KEY, pass --openai-api-key, "
        "or add api_key under config :openai in config/dev.secrets.exs."
    )


def main():
    args = parse_args()

    path = Path(args.path)
    source_text = path.read_text(encoding="utf-8")
    source_checksum = checksum(source_text)
    title = args.title or path.stem

    splitter = RecursiveCharacterTextSplitter.from_tiktoken_encoder(
        model_name=args.embedding_model,
        chunk_size=args.chunk_size,
        chunk_overlap=args.chunk_overlap,
        separators=["\n\n", "\n", ". ", " ", ""],
    )
    chunks = build_chunks(source_text, path.name, splitter)

    if not chunks:
        raise SystemExit("No chunks produced from input file")

    if args.dry_run:
        print_dry_run(chunks)

        if args.dry_run_output:
            write_dry_run_output(chunks, args.dry_run_output)
            print(f"Wrote chunks to: {args.dry_run_output}")

        return

    if not args.database_url:
        raise SystemExit("DATABASE_URL or --database-url is required")

    ensure_openai_api_key(args)

    import psycopg
    from langchain_openai import OpenAIEmbeddings
    from psycopg.types.json import Jsonb

    embedder = OpenAIEmbeddings(model=args.embedding_model)

    with psycopg.connect(args.database_url) as conn:
        with conn.transaction():
            existing = conn.execute(
                """
                SELECT id, status
                FROM rag_documents
                WHERE course_id = %s AND language = %s AND checksum = %s
                """,
                (args.course_id, args.language, source_checksum),
            ).fetchone()

            if existing:
                print(
                    f"Document already ingested: id={existing[0]} status={existing[1]}"
                )
                return

            timestamp = now()
            document_id = conn.execute(
                """
                INSERT INTO rag_documents (
                  course_id, title, source_filename, checksum, language, status,
                  embedding_model, metadata, inserted_at, updated_at
                )
                VALUES (%s, %s, %s, %s, %s, 'processing', %s, %s, %s, %s)
                RETURNING id
                """,
                (
                    args.course_id,
                    title,
                    path.name,
                    source_checksum,
                    args.language,
                    args.embedding_model,
                    Jsonb(
                        {
                            "chunk_size": args.chunk_size,
                            "chunk_overlap": args.chunk_overlap,
                            "total_chunks": len(chunks),
                            "section_count": section_count(chunks),
                            "section_aware": True,
                        }
                    ),
                    timestamp,
                    timestamp,
                ),
            ).fetchone()[0]

            chunk_index = 0
            for chunk_batch in batches(chunks, args.batch_size):
                contents = [chunk["content"] for chunk in chunk_batch]
                embeddings = embedder.embed_documents(contents)

                for chunk, embedding in zip(chunk_batch, embeddings):
                    timestamp = now()
                    conn.execute(
                        """
                        INSERT INTO rag_chunks (
                          rag_document_id, course_id, language, chunk_index, content,
                          token_count, metadata, embedding, inserted_at, updated_at
                        )
                        VALUES (%s, %s, %s, %s, %s, %s, %s, %s::vector, %s, %s)
                        """,
                        (
                            document_id,
                            args.course_id,
                            args.language,
                            chunk_index,
                            chunk["content"],
                            count_tokens(chunk["content"], args.embedding_model),
                            Jsonb(chunk["metadata"]),
                            vector_literal(embedding),
                            timestamp,
                            timestamp,
                        ),
                    )
                    chunk_index += 1

            conn.execute(
                "UPDATE rag_documents SET status = 'ready', updated_at = %s WHERE id = %s",
                (now(), document_id),
            )

    print(f"Ingested document id={document_id} chunks={len(chunks)}")


if __name__ == "__main__":
    main()
