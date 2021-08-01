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
  @spec get(integer()) :: [%Goal{}]
  def get(course_id) when is_ecto_id(course_id) do
    Goal
    |> where(course_id: ^course_id)
    |> Repo.all()
  end

  @doc """
  Returns goals with progress for each course_registration.
  """
  def get_with_progress(%CourseRegistration{id: course_reg_id}) do
    Goal
    |> join(:left, [g], p in assoc(g, :progress), on: p.course_reg_id == ^course_reg_id)
    |> preload([g, p], [:achievements, progress: p])
    |> Repo.all()
  end

  @spec upsert(map()) :: {:ok, %Goal{}} | {:error, {:bad_request, String.t()}}
  @doc """
  Inserts a new goal, or updates it if it already exists.
  """
  def upsert(attrs) do
    case attrs[:uuid] || attrs["uuid"] do
      nil ->
        {:error, {:bad_request, "No UUID specified in Goal"}}

      uuid ->
        Goal
        |> Repo.get(uuid)
        |> (&(&1 || %Goal{})).()
        |> Goal.changeset(attrs)
        |> Repo.insert_or_update()
        |> case do
          result = {:ok, _} ->
            result

          {:error, changeset} ->
            {:error, {:bad_request, full_error_messages(changeset)}}
        end
    end
  end

  @spec upsert_many([map()]) :: {:ok, [%Goal{}]} | {:error, {:bad_request, String.t()}}
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
  @spec delete(Ecto.UUID.t()) ::
          :ok | {:error, {:not_found, String.t()}}
  def delete(uuid) when is_binary(uuid) do
    case Goal
         |> where(uuid: ^uuid)
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
