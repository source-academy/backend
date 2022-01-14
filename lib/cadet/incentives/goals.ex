defmodule Cadet.Incentives.Goals do
  @moduledoc """
  Stores `Goal`s.
  """
  use Cadet, [:context, :display]

  alias Cadet.Incentives.{Goal, GoalProgress}

  alias Cadet.Accounts.CourseRegistration

  import Ecto.Query

  @doc """
  Returns all goals.
  """
  @spec get(integer()) :: [Goal.t()]
  def get(course_id) when is_ecto_id(course_id) do
    Goal
    |> where(course_id: ^course_id)
    |> Repo.all()
  end

  @doc """
  Returns goals with progress for each course_registration.
  """
  def get_with_progress(%CourseRegistration{id: course_reg_id, course_id: course_id}) do
    Goal
    |> where(course_id: ^course_id)
    |> join(:left, [g], p in assoc(g, :progress), on: p.course_reg_id == ^course_reg_id)
    |> preload([g, p], [:achievements, progress: p])
    |> Repo.all()
  end

  @spec upsert(map()) :: {:ok, Goal.t()} | {:error, {:bad_request, String.t()}}
  @doc """
  Inserts a new goal, or updates it if it already exists.
  """
  def upsert(attrs) do
    case {attrs[:uuid] || attrs["uuid"], attrs[:course_id] || attrs["course_id"]} do
      {nil, nil} ->
        {:error, {:bad_request, "No course ID or UUID specified in Goal"}}

      {nil, _} ->
        {:error, {:bad_request, "No UUID specified in Goal"}}

      {_, nil} ->
        {:error, {:bad_request, "No course ID specified in Goal"}}

      {uuid, course_id} ->
        goal = Repo.get(Goal, uuid) || %Goal{course_id: course_id}

        if goal.course_id == course_id do
          upsert_checked(goal, attrs)
        else
          {:error, {:bad_request, "Goal already exists in different course"}}
        end
    end
  end

  defp upsert_checked(goal, attrs) do
    goal
    |> Goal.changeset(attrs)
    |> Repo.insert_or_update()
    |> case do
      result = {:ok, _} ->
        result

      {:error, changeset} ->
        {:error, {:bad_request, full_error_messages(changeset)}}
    end
  end

  @spec upsert_many([map()]) :: {:ok, [Goal.t()]} | {:error, {:bad_request, String.t()}}
  def upsert_many(many_attrs) do
    Repo.transaction(fn ->
      for attrs <- many_attrs do
        case upsert(attrs) do
          {:ok, goal} -> goal
          {:error, error} -> Repo.rollback(error)
        end
      end
    end)
  end

  @doc """
  Deletes a goal.
  """
  @spec delete(Ecto.UUID.t(), integer()) ::
          :ok | {:error, {:not_found, String.t()}}
  def delete(uuid, course_id) when is_binary(uuid) do
    case Goal
         |> where(uuid: ^uuid, course_id: ^course_id)
         |> Repo.delete_all() do
      {0, _} -> {:error, {:not_found, "Goal not found"}}
      {_, _} -> :ok
    end
  end

  def upsert_progress(attrs, goal_uuid, course_reg_id) do
    if goal_uuid == nil or course_reg_id == nil do
      {:error, {:bad_request, "No UUID specified in Goal"}}
    else
      course_reg = Repo.get(CourseRegistration, course_reg_id)
      goal = Repo.get_by(Goal, uuid: goal_uuid, course_id: course_reg.course_id)

      case goal do
        nil ->
          {:error, {:bad_request, "User and goal are not in the same course"}}

        _ ->
          GoalProgress
          |> Repo.get_by(goal_uuid: goal_uuid, course_reg_id: course_reg_id)
          |> (&(&1 || %GoalProgress{})).()
          |> GoalProgress.changeset(attrs)
          |> Repo.insert_or_update()
          |> case do
            result = {:ok, _} ->
              result

            {:error, changeset} ->
              {:error, {:bad_request, full_error_messages(changeset)}}
          end
      end
    end
  end
end
