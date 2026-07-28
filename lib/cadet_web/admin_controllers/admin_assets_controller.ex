defmodule CadetWeb.AdminAssetsController do
  use CadetWeb, :controller
  use OpenApiSpex.ControllerSpecs

  # :upload is multipart/form-data and :delete has a wildcard (`*filename`) path
  # segment; skip request validation for both.
  plug(
    OpenApiSpex.Plug.CastAndValidate,
    [render_error: CadetWeb.Plugs.OpenApiErrorRenderer, replace_params: false]
    when action not in [:upload, :delete]
  )

  alias Cadet.Assets.Assets
  alias Cadet.Courses
  alias CadetWeb.ApiSpec.ErrorResponses
  alias OpenApiSpex.Schema

  tags(["Assets"])
  security([%{"JWT" => []}])

  operation(:index,
    summary: "Get all asset paths in a folder",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"],
      foldername: [in: :path, type: :string, required: true, description: "Folder name"]
    ],
    responses: [
      ok:
        {"List of asset paths", "application/json",
         %Schema{type: :array, items: %Schema{type: :string}}},
      bad_request: ErrorResponses.bad_request(),
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden()
    ]
  )

  def index(conn, _params = %{"foldername" => foldername}) do
    course_reg = conn.assigns.course_reg

    case Assets.list_assets(Courses.assets_prefix(course_reg.course), foldername) do
      {:error, {status, message}} -> conn |> put_status(status) |> text(message)
      assets -> render(conn, "index.json", assets: assets)
    end
  end

  operation(:delete,
    summary: "Delete a file from an asset folder",
    description:
      "The file path (which may contain subfolders) is the trailing `*filename` segment.",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"],
      foldername: [in: :path, type: :string, required: true, description: "Folder name"]
    ],
    responses: [
      no_content: "File deleted",
      bad_request: ErrorResponses.bad_request(),
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden(),
      not_found: ErrorResponses.not_found()
    ]
  )

  @spec delete(Plug.Conn.t(), map) :: Plug.Conn.t()
  def delete(conn, _params = %{"foldername" => foldername, "filename" => filename}) do
    course_reg = conn.assigns.course_reg
    filename = Enum.join(filename, "/")

    case Assets.delete_object(Courses.assets_prefix(course_reg.course), foldername, filename) do
      {:error, {status, message}} -> conn |> put_status(status) |> text(message)
      _ -> conn |> put_status(204) |> text("")
    end
  end

  # Ignore the dialyzer warning, just ctrl click the
  # `Assets.upload_to_s3` function to see the type,
  # it clearly returns a string URL
  @dialyzer {:no_match, upload: 2}

  operation(:upload,
    summary: "Upload a file to an asset folder",
    description:
      "The file path (which may contain subfolders) is the trailing `*filename` segment.",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"],
      foldername: [in: :path, type: :string, required: true, description: "Folder name"]
    ],
    request_body:
      {"The file to upload", "multipart/form-data",
       %Schema{
         type: :object,
         properties: %{upload: %Schema{type: :string, format: :binary}},
         required: [:upload]
       }},
    responses: [
      ok: {"URL of the uploaded asset", "application/json", %Schema{type: :string}},
      bad_request: ErrorResponses.bad_request(),
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden()
    ]
  )

  def upload(conn, %{
        "upload" => upload_params,
        "filename" => filename,
        "foldername" => foldername
      }) do
    course_reg = conn.assigns.course_reg
    filename = Enum.join(filename, "/")

    case Assets.upload_to_s3(
           upload_params,
           Courses.assets_prefix(course_reg.course),
           foldername,
           filename
         ) do
      {:error, {status, message}} -> conn |> put_status(status) |> text(message)
      resp -> render(conn, "show.json", resp: resp)
    end
  end
end
