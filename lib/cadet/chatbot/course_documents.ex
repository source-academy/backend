defmodule Cadet.Chatbot.CourseDocuments do
  @moduledoc """
  Manages course-scoped pixelbot categories/documents and provides lookup utilities for the
  RAG pipeline.
  """
  require Logger
  import Ecto.Query

  alias Cadet.Repo
  alias Cadet.Chatbot.{DocumentUploader, PixelbotCategory, PixelbotDocument, Slug}

  # ---- Categories ----------------------------------------------------------

  def list_categories(course_id) do
    PixelbotCategory
    |> where([c], c.course_id == ^course_id)
    |> order_by([c], asc: c.name)
    |> Repo.all()
  end

  def create_category(course_id, name) do
    %PixelbotCategory{}
    |> PixelbotCategory.changeset(%{course_id: course_id, name: name})
    |> Repo.insert()
  end

  def rename_category(course_id, category_id, new_name) do
    case get_category(course_id, category_id) do
      nil ->
        {:error, :not_found}

      category ->
        category
        |> PixelbotCategory.changeset(%{name: new_name})
        |> Repo.update()
    end
  end

  def delete_category(course_id, category_id) do
    case get_category(course_id, category_id) do
      nil ->
        {:error, :not_found}

      category ->
        document_count =
          PixelbotDocument
          |> where([d], d.category_id == ^category_id)
          |> Repo.aggregate(:count, :id)

        if document_count > 0 do
          {:error, {:bad_request, "This category still has #{document_count} document(s)"}}
        else
          Repo.delete(category)
        end
    end
  end

  defp get_category(course_id, category_id) do
    case cast_id(category_id) do
      {:ok, id} ->
        PixelbotCategory
        |> where([c], c.course_id == ^course_id and c.id == ^id)
        |> Repo.one()

      :error ->
        nil
    end
  end

  # ---- Documents (admin-facing) --------------------------------------------

  def list_documents(course_id) do
    PixelbotDocument
    |> where([d], d.course_id == ^course_id)
    |> order_by([d], asc: d.inserted_at)
    |> Repo.all()
  end

  def list_documents_for_category(course_id, category_id) do
    case cast_id(category_id) do
      {:ok, id} ->
        PixelbotDocument
        |> where([d], d.course_id == ^course_id and d.category_id == ^id)
        |> order_by([d], asc: d.inserted_at)
        |> Repo.all()

      :error ->
        []
    end
  end

  @doc """
  Inserts one row per entry. Each must carry an `s3_key` already validated against the
  `course-<id>/` prefix by the admin controller.
  """
  def create_documents(course_id, entries) do
    if Repo.in_transaction?() do
      {:ok, insert_documents(course_id, entries)}
    else
      Repo.transaction(fn -> insert_documents(course_id, entries) end)
    end
  end

  defp insert_documents(course_id, entries) do
    Enum.map(entries, fn entry ->
      category_id = entry["category_id"] || entry[:category_id]

      unless category_belongs_to_course?(course_id, category_id) do
        Repo.rollback({:bad_request, "Invalid category"})
      end

      normalized = normalize_entry(entry)
      title = normalized[:title]

      unless is_binary(title) and String.trim(title) != "" do
        changeset =
          %PixelbotDocument{}
          |> PixelbotDocument.changeset(
            Map.merge(normalized, %{course_id: course_id, doc_key: ""})
          )

        Repo.rollback(changeset)
      end

      doc_key =
        Slug.unique(Slug.slugify(title), fn candidate ->
          doc_key_taken?(course_id, candidate)
        end)

      params = Map.merge(normalized, %{course_id: course_id, doc_key: doc_key})

      case %PixelbotDocument{} |> PixelbotDocument.changeset(params) |> Repo.insert() do
        {:ok, document} -> document
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  def update_document(course_id, document_id, params) do
    category_id = params["category_id"] || params[:category_id]

    with %PixelbotDocument{} = document <- get_document(course_id, document_id),
         true <- is_nil(category_id) or category_belongs_to_course?(course_id, category_id) do
      document
      |> PixelbotDocument.changeset(normalize_entry(params))
      |> Repo.update()
    else
      nil -> {:error, :not_found}
      false -> {:error, {:bad_request, "Invalid category"}}
    end
  end

  defp category_belongs_to_course?(course_id, category_id) do
    case cast_id(category_id) do
      {:ok, id} ->
        PixelbotCategory
        |> where([c], c.course_id == ^course_id and c.id == ^id)
        |> Repo.exists?()

      :error ->
        false
    end
  end

  @doc """
  Renames a document's underlying file. Unlike a category rename (which would touch every
  document in it), this touches exactly one S3 object, so it's safe to actually move it.
  """
  def rename_document(course_id, document_id, new_filename) do
    case get_document(course_id, document_id) do
      nil ->
        {:error, :not_found}

      document ->
        rename_stored_document(document, new_filename, course_id)
    end
  end

  defp rename_stored_document(document, new_filename, course_id) do
    case DocumentUploader.rename(document.s3_key, new_filename, course_id) do
      {:ok, %{s3_key: s3_key, media_type: media_type}} ->
        update_result =
          Repo.transaction(fn ->
            document
            |> PixelbotDocument.changeset(%{
              s3_key: s3_key,
              media_type: media_type,
              filename: new_filename
            })
            |> Repo.update()
            |> case do
              {:ok, updated_document} -> updated_document
              {:error, reason} -> Repo.rollback(reason)
            end
          end)

        restore_after_failed_rename(update_result, document.s3_key, s3_key)

      {:error, _} = error ->
        error
    end
  end

  defp restore_after_failed_rename({:ok, document}, _old_s3_key, _new_s3_key),
    do: {:ok, document}

  defp restore_after_failed_rename(error = {:error, _reason}, old_s3_key, new_s3_key) do
    if old_s3_key != new_s3_key do
      case DocumentUploader.restore_rename(new_s3_key, old_s3_key) do
        :ok ->
          :ok

        {:error, restore_reason} ->
          Logger.error("Failed to compensate document rename: #{inspect(restore_reason)}")
      end
    end

    error
  end

  def delete_document(course_id, document_id) do
    case get_document(course_id, document_id) do
      nil ->
        {:error, :not_found}

      document ->
        case Repo.delete(document) do
          {:ok, deleted} ->
            DocumentUploader.delete(deleted.s3_key)
            {:ok, deleted}

          {:error, _} = error ->
            error
        end
    end
  end

  def get_document(course_id, document_id) do
    case cast_id(document_id) do
      {:ok, id} ->
        PixelbotDocument
        |> where([d], d.course_id == ^course_id and d.id == ^id)
        |> Repo.one()

      :error ->
        nil
    end
  end

  @doc false
  # `is_ecto_id` accepts any binary, so a malformed id must be rejected before it reaches Ecto,
  # which would raise Ecto.Query.CastError (a plain 500) instead of returning :not_found.
  defp cast_id(id) when is_integer(id), do: {:ok, id}

  defp cast_id(id) when is_binary(id) do
    case Integer.parse(id) do
      {int, ""} -> {:ok, int}
      _ -> :error
    end
  end

  defp cast_id(_), do: :error

  defp doc_key_taken?(course_id, doc_key) do
    PixelbotDocument
    |> where([d], d.course_id == ^course_id and d.doc_key == ^doc_key)
    |> Repo.exists?()
  end

  defp normalize_entry(entry) do
    entry
    |> Enum.into(%{}, fn {k, v} -> {to_string(k), v} end)
    |> Map.take(~w(category_id title description release_date s3_key filename media_type))
    |> Enum.into(%{}, fn {k, v} -> {String.to_atom(k), v} end)
  end

  # ---- RAG pipeline lookups (string-keyed, matches the old JSON shape) -----

  @doc """
  Builds the routing prompt's document map, omitting anything the LLM shouldn't see and any
  document not yet released. `Jason.OrderedObject` keeps key order; a plain map would sort it.
  """
  def build_document_map_json(course_id) do
    PixelbotDocument
    |> where([d], d.course_id == ^course_id)
    |> where([d], is_nil(d.release_date) or d.release_date <= ^Date.utc_today())
    |> join(:inner, [d], c in PixelbotCategory, on: c.id == d.category_id)
    |> select([d, c], %{
      doc_key: d.doc_key,
      title: d.title,
      description: d.description,
      doc_type: c.name,
      release_date: d.release_date
    })
    |> Repo.all()
    |> Enum.map(fn doc ->
      Jason.OrderedObject.new(
        [
          {"id", doc.doc_key},
          {"title", doc.title},
          {"description", doc.description},
          {"doc_type", doc.doc_type}
        ] ++
          optional_pair("release_date", doc.release_date)
      )
    end)
  end

  defp optional_pair(_key, nil), do: []
  defp optional_pair(key, value), do: [{key, value}]

  @doc """
  Returns the documents named by `ids`, scoped to `course_id` so one course's routing response
  can't reach another's. Re-applies the released-only filter in case it changed since routing.
  """
  def get_documents_by_ids(course_id, ids) when is_list(ids) do
    PixelbotDocument
    |> where([d], d.course_id == ^course_id and d.doc_key in ^ids)
    |> where([d], is_nil(d.release_date) or d.release_date <= ^Date.utc_today())
    |> Repo.all()
    |> Enum.map(fn doc ->
      %{
        "id" => doc.doc_key,
        "title" => doc.title,
        "s3_key" => doc.s3_key,
        "media_type" => doc.media_type
      }
    end)
  end
end
