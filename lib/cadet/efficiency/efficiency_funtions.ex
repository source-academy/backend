defmodule Cadet.Efficiency do
  @moduledoc """
  Courses context contains domain logic for Course administration
  management such as course configuration, discussion groups and materials
  """
  use Cadet, [:context, :display]

  import Ecto.Query

  alias Cadet.Assessments.{
    Answer,
    Submission
  }

  alias Cadet.Efficiency.{
    Efficiency,
    Runtimes
  }

  def update_runtimes(assessment_id, question_id, user_id)
      when is_ecto_id(assessment_id) and is_ecto_id(question_id) and is_ecto_id(user_id) do
    # Repo.insert!(
    #    %Runtimes{assessment_id: assessment_id, user_id: user_id, counter: 0},
    #    on_conflict: [inc: [counter: 1]],
    #    conflict_target: [:assessment_id, :user_id]
    #    )

    {assessment_id, ""} = Integer.parse(assessment_id)
    {question_id, ""} = Integer.parse(question_id)
    {user_id, ""} = Integer.parse(user_id)

    schema =
      Repo.get_by(Runtimes,
        assessment_id: assessment_id,
        question_id: question_id,
        user_id: user_id
      )

    if schema do
      changeset = Ecto.Changeset.change(schema, counter: schema.counter + 1)
      Repo.update(changeset)
    else
      new_schema = %Runtimes{
        assessment_id: assessment_id,
        question_id: question_id,
        user_id: user_id,
        counter: 1
      }

      Repo.insert(new_schema)
    end
  end

  def get_efficiency_real_data(id, question_id) when is_ecto_id(id) and is_ecto_id(question_id) do
    {id, ""} = Integer.parse(id)
    {question_id, ""} = Integer.parse(question_id)
    efficiency = efficiency_real_data(id, question_id)
    %{efficiency: efficiency}
  end

  defp efficiency_real_data(id, question_id) when is_ecto_id(id) and is_ecto_id(question_id) do
    Runtimes
    |> where(assessment_id: ^id, question_id: ^question_id)
    |> join(:left, [r], s in Submission, on: r.user_id == s.student_id)
    |> join(:left, [_, s], a in Answer, on: s.id == a.submission_id)
    |> select(
      [r, s, a],
      {r.user_id, r.counter, s.inserted_at, s.updated_at, a.xp, a.xp_adjustment}
    )
    |> Repo.all()
    |> Enum.map(fn {a, b, c, d, e, f} ->
      %{sid: a, runtimes: b, inserted_at: c, updated_at: d, xp: e, xp_adjustment: f}
    end)
    |> Jason.encode!()
  end
end
