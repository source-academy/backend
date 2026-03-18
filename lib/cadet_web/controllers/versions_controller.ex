defmodule CadetWeb.VersionsController do
  @moduledoc """
  Handles code versioning and history
  """
  use CadetWeb, :controller
  use PhoenixSwagger
  require Logger

  alias Cadet.Assessments

  def history(conn, %{"questionid" => question_id}) do
    course_reg = conn.assigns[:course_reg]

    Logger.info(
      "Fetching all versions for question #{question_id} for user #{course_reg.id} in course #{course_reg.course_id}"
    )

    with {:question, question} when not is_nil(question) <-
           {:question, Assessments.get_question(question_id)},
         {:versions, versions} <-
           {:versions, Assessments.get_version(question, course_reg)} do
      conn
      |> put_status(:ok)
      |> put_resp_content_type("application/json")
      |> render("index.json", versions: versions)
    else
      {:question, nil} ->
        conn
        |> put_status(:not_found)
        |> text("Question not found")
    end
  end

  def save(conn, %{"questionid" => question_id, "version" => version}) do
    course_reg = conn.assigns[:course_reg]

    with {:question, question} when not is_nil(question) <-
           {:question, Assessments.get_question(question_id)},
         {:ok, _nil} <- Assessments.save_version(question, course_reg, version) do
      text(conn, "OK")
    else
      {:question, nil} ->
        conn
        |> put_status(:not_found)
        |> text("Question not found")

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end

  def name(conn, %{
        "questionid" => question_id,
        "versionid" => version_id,
        "name" => name
      }) do
    course_reg = conn.assigns[:course_reg]

    with {:question, question} when not is_nil(question) <-
           {:question, Assessments.get_question(question_id)},
         {:ok, _nil} <- Assessments.name_version(question, course_reg, version_id, name) do
      text(conn, "OK")
    else
      {:question, nil} ->
        conn
        |> put_status(:not_found)
        |> text("Question not found")

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end
end
