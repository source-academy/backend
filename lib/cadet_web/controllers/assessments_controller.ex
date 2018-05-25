defmodule CadetWeb.AssessmentController do
  use CadetWeb, :controller

  alias Cadet.Assessments

  def index(conn, params) do
    Assessments.all_missions(type)
  end

  def new(conn, _params) do
    Poison.encode!(%{"changeset" => Assessments.build_mission(%{})})
  end

  def show(conn, %{"id" => id}) do
    mission = Assessments.get_mission_and_questions(id)
    question_changeset = Assessments.build_question(%{})
    Poison.encode!(%{mission: mission, question_changeset: question_changeset})
  end

  def edit(conn, %{"id" => id}) do
    Poison.encode!(%{"changeset" => Assessments.change_mission(id, %{})})
  end

  def create(conn, %{"mission" => params}) do
    Assessments.create_mission(params)
  end

  def update(conn, %{"id" => id, "mission" => params}) do
    Assessments.update_mission(id, params)
  end

  def publish(conn, %{"mission_id" => id}) do
    Assessments.publish_assessment(id)
  end

  def submissions(conn, %{"mission_id" => id}) do
    mission = Assessments.get_mission(id)
    submissions = Assessments.submissions_of_assessment(mission)
    not_attempted = Assessments.students_not_attempted(mission)

    Poison.encode!(%{
      "mission" => mission,
      "submissions" => submissions,
      "not_attempted" => not_attempted
    })
  end

  def unsubmit(conn, %{"mission_id" => mid, "id" => id}) do
    Assessments.unsubmit_submission(id)
  end

  def edit_grade(conn, %{
        "mission_id" => mission_id,
        "id" => submission_id
      }) do
    submission = Assessments.get_submission(submission_id)
    changeset = Assessments.build_grading(submission)
    Poison.encode!(%{"changeset" => changeset})
  end

  def update_grade(conn, %{
        "mission_id" => mid,
        "id" => id,
        "submission" => params
      }) do
    grader = conn.assigns.current_user
    Assessments.update_grading(id, params, grader)
  end
end
