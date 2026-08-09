defmodule CadetWeb.AdminPixelbotDocumentsController do
  use CadetWeb, :controller
  require Logger

  alias Cadet.Chatbot.{CourseDocuments, DocumentUploader, MetadataGenerator}
  alias Cadet.Repo

  # ---- Categories -----------------------------------------------------------

  def index(conn, _params) do
    course_id = course_id(conn)

    render(conn, "index.json", %{
      categories: CourseDocuments.list_categories(course_id),
      documents: CourseDocuments.list_documents(course_id)
    })
  end

  def create_category(conn, %{"name" => name}) when is_binary(name) do
    case CourseDocuments.create_category(course_id(conn), name) do
      {:ok, category} -> render(conn, "category.json", %{category: category})
      {:error, changeset} -> respond_changeset_error(conn, changeset)
    end
  end

  def create_category(conn, _params) do
    send_resp(conn, :bad_request, "Missing category name")
  end

  def rename_category(conn, %{"category_id" => category_id, "name" => name})
      when is_ecto_id(category_id) and is_binary(name) do
    case CourseDocuments.rename_category(course_id(conn), category_id, name) do
      {:ok, category} -> render(conn, "category.json", %{category: category})
      {:error, :not_found} -> send_resp(conn, :not_found, "Category not found")
      {:error, changeset} -> respond_changeset_error(conn, changeset)
    end
  end

  def delete_category(conn, %{"category_id" => category_id}) when is_ecto_id(category_id) do
    case CourseDocuments.delete_category(course_id(conn), category_id) do
      {:ok, _} -> send_resp(conn, :no_content, "")
      {:error, :not_found} -> send_resp(conn, :not_found, "Category not found")
      {:error, {:bad_request, message}} -> send_resp(conn, :bad_request, message)
    end
  end

  def upload(conn, %{"category_id" => category_id, "files" => files})
      when is_ecto_id(category_id) do
    case validate_uploads(files) do
      {:ok, uploads} ->
        process_uploads(conn, category_id, uploads)

      {:error, :invalid_upload} ->
        upload(conn, %{})
    end
  end

  def upload(conn, _params) do
    send_resp(conn, :bad_request, "Missing category_id or files")
  end

  defp process_uploads(conn, category_id, uploads) do
    course = conn.assigns.course_reg.course

    {entries, _claimed} =
      Enum.reduce(uploads, {[], MapSet.new()}, fn %Plug.Upload{} = upload, {acc, claimed} ->
        course_id = course.id

        case DocumentUploader.upload(upload.filename, upload.path, course_id, claimed) do
          {:ok, %{s3_key: s3_key, media_type: media_type}} ->
            metadata = generate_metadata(upload, s3_key, media_type, course)

            entry = %{
              status: "ready",
              categoryId: category_id,
              s3Key: s3_key,
              filename: upload.filename,
              mediaType: media_type,
              title: metadata.title,
              description: metadata.description,
              # The LLM can't know this; the admin fills it in before saving.
              releaseDate: nil
            }

            {[entry | acc], MapSet.put(claimed, s3_key)}

          {:error, {:bad_request, message}} ->
            Logger.warning("Pixelbot upload failed for #{upload.filename}: #{message}")

            entry = %{
              status: "error",
              categoryId: category_id,
              filename: upload.filename,
              error: message
            }

            {[entry | acc], claimed}
        end
      end)

    json(conn, %{entries: Enum.reverse(entries)})
  end

  defp validate_uploads(files) do
    uploads = List.wrap(files)

    if uploads != [] and Enum.all?(uploads, &match?(%Plug.Upload{}, &1)),
      do: {:ok, uploads},
      else: {:error, :invalid_upload}
  end

  @doc """
  Bulk-saves new entries from upload/2 plus edits to existing ones. Every s3Key is re-validated
  against this course's prefix so an admin can't graft another course's object onto their map.
  """
  def save(conn, %{"entries" => entries}) when is_list(entries) do
    course_id = course_id(conn)
    entries = Enum.map(entries, &normalize_save_entry/1)

    {new_entries, existing_entries} = Enum.split_with(entries, &is_nil(&1[:id]))

    with :ok <- validate_s3_keys(new_entries, course_id),
         {:ok, _inserted} <- save_entries(course_id, new_entries, existing_entries) do
      render(conn, "index.json", %{
        categories: CourseDocuments.list_categories(course_id),
        documents: CourseDocuments.list_documents(course_id)
      })
    else
      {:error, {:bad_request, message}} -> send_resp(conn, :bad_request, message)
      {:error, changeset} -> respond_changeset_error(conn, changeset)
    end
  end

  def save(conn, _params) do
    send_resp(conn, :bad_request, "Missing entries")
  end

  defp save_entries(course_id, new_entries, existing_entries) do
    Repo.transaction(fn ->
      with {:ok, inserted} <- CourseDocuments.create_documents(course_id, new_entries),
           :ok <- update_existing(course_id, existing_entries) do
        inserted
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  def rename(conn, %{"document_id" => document_id, "filename" => filename})
      when is_ecto_id(document_id) and is_binary(filename) do
    case CourseDocuments.rename_document(course_id(conn), document_id, filename) do
      {:ok, document} -> render(conn, "document.json", %{document: document})
      {:error, :not_found} -> send_resp(conn, :not_found, "Document not found")
      {:error, {:bad_request, message}} -> send_resp(conn, :bad_request, message)
      {:error, changeset} -> respond_changeset_error(conn, changeset)
    end
  end

  def delete(conn, %{"document_id" => document_id}) when is_ecto_id(document_id) do
    case CourseDocuments.delete_document(course_id(conn), document_id) do
      {:ok, _} -> send_resp(conn, :no_content, "")
      {:error, :not_found} -> send_resp(conn, :not_found, "Document not found")
      {:error, changeset} -> respond_changeset_error(conn, changeset)
    end
  end

  def preview_map(conn, _params) do
    json(conn, %{documentMap: CourseDocuments.build_document_map_json(course_id(conn))})
  end

  defp course_id(conn), do: conn.assigns.course_reg.course_id

  defp generate_metadata(upload, _s3_key, media_type, course) do
    case File.read(upload.path) do
      {:ok, binary} ->
        base64 = Base.encode64(binary)
        model = course.llm_model || "gpt-4o"
        MetadataGenerator.generate(upload.filename, base64, media_type, model)

      {:error, reason} ->
        Logger.warning("Could not read #{upload.filename} for metadata: #{inspect(reason)}")
        %{title: Path.rootname(upload.filename), description: ""}
    end
  end

  @save_entry_keys %{
    "id" => :id,
    "categoryId" => :category_id,
    "title" => :title,
    "description" => :description,
    "releaseDate" => :release_date,
    "s3Key" => :s3_key,
    "filename" => :filename,
    "mediaType" => :media_type
  }

  defp normalize_save_entry(entry) do
    Enum.reduce(@save_entry_keys, %{}, fn {camel_key, atom_key}, acc ->
      case Map.fetch(entry, camel_key) do
        {:ok, value} -> Map.put(acc, atom_key, value)
        :error -> acc
      end
    end)
  end

  defp validate_s3_keys(entries, course_id) do
    prefix = "course-#{course_id}/"

    invalid =
      Enum.find(entries, fn entry ->
        s3_key = entry[:s3_key]
        is_nil(s3_key) or not String.starts_with?(s3_key, prefix)
      end)

    if invalid do
      {:error, {:bad_request, "Invalid document reference"}}
    else
      :ok
    end
  end

  defp update_existing(course_id, entries) do
    Enum.reduce_while(entries, :ok, fn entry, :ok ->
      params = Map.take(entry, [:category_id, :title, :description, :release_date])

      case CourseDocuments.update_document(course_id, entry[:id], params) do
        {:ok, _} -> {:cont, :ok}
        {:error, :not_found} -> {:halt, {:error, {:bad_request, "Document not found"}}}
        {:error, {:bad_request, message}} -> {:halt, {:error, {:bad_request, message}}}
        {:error, changeset} -> {:halt, {:error, changeset}}
      end
    end)
  end

  defp respond_changeset_error(conn, changeset) do
    conn
    |> put_status(:bad_request)
    |> json(%{errors: translate_changeset_errors(changeset)})
  end

  defp translate_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
  end
end
