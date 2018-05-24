defmodule CadetWeb.QuestionController do
  use CadetWeb, :controller

  alias Cadet.Assessments

  def create(conn, %{"mission_id" => mission_id, "question" => params}) do
    type = Map.get(params, "problem_type")
    Assessments.create_question(params, type, mission_id) do
  end

  def edit(conn, %{"mission_id" => mission_id, "id" => id} = params) do
    tab = params["tab"] || "Content"
    question = Assessments.get_question(id)
    mission = Assessments.get_mission(mission_id)
    changeset = Assessments.change_question(question, %{})
    params = Map.merge(%{
      tab: tab,
      mission: mission,
      question: question,
      changeset: changeset
    })
  end

  def update(conn, params) do
    mission_id = params["mission_id"]
    Assessments.update_question(params["id"], params["question"])
  end

  def delete(conn, %{"mission_id" => mission_id, "id" => id}) do
    Assessments.delete_question(id)
end
