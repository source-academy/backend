defmodule CadetWeb.EfficiencyController do
  use CadetWeb, :controller
  alias Cadet.Efficiency

  def real_data(conn, %{"id" => id, "question_id" => question_id}) do
    efficiency = Efficiency.getEfficiencyRealData(id, question_id)
    json(conn, efficiency.efficiency)
  end

end