defmodule CadetWeb.QuestionController do
  use CadetWeb, :controller
  alias Cadet.Assessments

  def create(conn, %{"mission_id" => mission_id, "question" => params}) do
    type = Map.get(params, "problem_type")
    Assessments.create_question(params, type, mission_id)
  end

  def edit(conn, params = %{"mission_id" => mission_id, "id" => id}) do
    tab = params["tab"] || "Content"
    question = Assessments.get_question(id)
    mission = Assessments.get_mission(mission_id)
    changeset = Assessments.change_question(question, %{})

    Poison.encode!(%{
      "tab" => tab,
      "question" => question,
      "mission" => mission,
      "changeset" => changeset
    })
  end

  def update(conn, params) do
    mission_id = params["mission_id"]
    Assessments.update_question(params["id"], params["question"])
  end

  def delete(conn, %{"mission_id" => mission_id, "id" => id}) do
    Assessments.delete_question(id)
  end
end
