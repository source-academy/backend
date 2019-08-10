defmodule CadetWeb.CategoryController do
  use CadetWeb, :controller
  use PhoenixSwagger

  alias Cadet.{Course, Repo}
  alias Course.Category

  def create(conn, %{"title" => title, "parentId" => category_id}) do
    category =
      if category_id do
        Repo.get(Category, category_id)
      else
        nil
      end

    result = Course.create_material_folder(category, conn.assigns.current_user, %{title: title})

    case result do
      {:ok, _nil} ->
        send_resp(conn, 200, "OK")

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end

  def create(conn, _params) do
    send_resp(conn, :bad_request, "Missing or invalid parameter(s)")
  end

  def delete(conn, %{"id" => id}) do
    result = Course.delete_category(conn.assigns.current_user, id)

    case result do
      {:ok, _nil} ->
        send_resp(conn, 200, "OK")

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end

  swagger_path :create do
    post("/category")
    description("Create folder")
    summary("Create folder")
    security([%{JWT: []}])

    parameters do
      material(:body, Schema.ref(:Category), "folder details", required: true)
    end

    response(200, "Success")
    response(400, "Invalid or missing parameter(s)")
    response(401, "Unauthorised")
  end

  swagger_path :delete do
    PhoenixSwagger.Path.delete("/category/{id}")
    description("Deletes folder by specifying the folder id")
    summary("Delete folder")
    security([%{JWT: []}])

    parameters do
      id(:path, :integer, "folder id", required: true)
    end

    response(200, "Success")
    response(400, "Invalid or missing parameter(s)")
    response(401, "Unauthorised")
  end

  def swagger_definitions do
    %{
      Category:
        swagger_schema do
          properties do
            title(:string, "title", required: true)
            description(:string, "description", required: false)
          end
        end
    }
  end
end
