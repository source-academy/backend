defmodule CadetWeb.AdminStoriesController do
  use CadetWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias Cadet.Stories.Stories
  alias CadetWeb.ApiSpec.ErrorResponses
  alias CadetWeb.Schemas

  tags(["Stories"])
  security([%{"JWT" => []}])

  operation(:create,
    summary: "Create a new story",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"]
    ],
    request_body: {"The story to create", "application/json", Schemas.StoryRequest},
    responses: [
      ok: "Story created",
      bad_request: ErrorResponses.bad_request(),
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden()
    ]
  )

  def create(conn, %{"course_id" => course_id, "story" => story}) do
    result =
      story
      |> to_snake_case_atom_keys()
      |> Stories.create_story(course_id |> String.to_integer())

    case result do
      {:ok, _story} ->
        conn |> put_status(200) |> text("")

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end

  operation(:update,
    summary: "Update an existing story",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"],
      storyid: [in: :path, type: :integer, required: true, description: "Story ID"]
    ],
    request_body: {"The story properties to update", "application/json", Schemas.StoryRequest},
    responses: [
      ok: "Story updated",
      bad_request: ErrorResponses.bad_request(),
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden(),
      not_found: ErrorResponses.not_found()
    ]
  )

  def update(conn, _params = %{"course_id" => course_id, "storyid" => id, "story" => story}) do
    result =
      story
      |> to_snake_case_atom_keys()
      |> Stories.update_story(id, course_id |> String.to_integer())

    case result do
      {:ok, _story} ->
        conn |> put_status(200) |> text("")

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end

  operation(:delete,
    summary: "Delete a story",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"],
      storyid: [in: :path, type: :integer, required: true, description: "Story ID"]
    ],
    responses: [
      no_content: "Story deleted",
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden(),
      not_found: ErrorResponses.not_found()
    ]
  )

  def delete(conn, _params = %{"course_id" => course_id, "storyid" => id}) do
    result = Stories.delete_story(id, course_id |> String.to_integer())

    case result do
      {:ok, _nil} ->
        conn |> put_status(204) |> text("")

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end
end
