defmodule CadetWeb.VersionController do
  @moduledoc """
  Handles code versioning and history
  """
  use CadetWeb, :controller
  use PhoenixSwagger
  require Logger

  alias Cadet.Assessments

  def history(conn, %{"questionid" => question_id}) do
    course_reg = conn.assigns[:course_reg]

    Logger.info("Fetching all versions for question #{question_id} for user #{course_reg.id} in course #{course_reg.course_id}")

    with {:question, question} when not is_nil(question) <-
           {:question, Assessments.get_question(question_id)},
         {:versions, versions} <-
          {:versions, Assessments.get_version(question, course_reg)} do
      # TODO
      # render()
    else
      {:question, nil} ->
        conn
        |> put_status(:not_found)
        |> text("Question not found")
    end
  end

  def save(conn, _params) do
    # TODO

    text(conn, "save")
  end

  def name(conn, _params) do
    # TODO

    text(conn, "save")
  end
end
