defmodule Cadet.Assessments.Query do
  @moduledoc """
  Generate queries related to the Assessments context
  """

  import Ecto.Query

  alias Cadet.Assessments.Answer

  def submissions_xp do
    Answer
    |> select([a], %{submission_id: a.submission_id, xp: sum(a.xp)})
    |> group_by([a], a.submission_id)
  end
end
