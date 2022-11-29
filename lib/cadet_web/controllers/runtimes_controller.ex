defmodule CadetWeb.RuntimesController do
  use CadetWeb, :controller
  alias Cadet.Efficiency
  
  def index(conn,  %{"assessmentId" => assessmentId, "questionId" => questionId, "userId" => userId}) do
	result = Efficiency.update_runtimes(assessmentId, questionId, userId)
  end

end