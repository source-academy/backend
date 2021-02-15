defmodule CadetWeb.ContestVotingController do
  use CadetWeb, :controller
  use PhoenixSwagger

  alias Cadet.Assessments

  def show(
        conn,
        %{
          "assessmentid" => assessment_id,
          "userid" => user_id
        }
      )
      when is_ecto_id(assessment_id) and is_ecto_id(user_id) do
    case Assessments.all_submission_votes_by_assessment_id_and_user_id(assessment_id, user_id) do
      # pull contest entry data for user and assessment id
      {:ok, submission_votes} ->
        json(conn, submission_votes)
    end
  end
end
