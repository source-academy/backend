defmodule Cadet.Incentives.Achievements do
  @moduledoc """
  Stores `Achievement`s.
  """
  use Cadet, [:context, :display]

  alias Cadet.Incentives.{Achievement, GoalProgress}

  import Ecto.Query
  require Logger

  require Decimal

  @doc """
  Returns all achievements.

  This returns Achievement structs with prerequisites and goal association maps pre-loaded.
  """
  @spec get(integer()) :: [Achievement.t()]
  def get(course_id) when is_ecto_id(course_id) do
    Logger.info("Retrieving achievements for course #{course_id}")

    achievements =
      Achievement
      |> where(course_id: ^course_id)
      |> preload([:prerequisites, :goals])
      |> Repo.all()

    Logger.info("Retrieved #{length(achievements)} achievements for course #{course_id}")
    achievements
  end

  @doc """
  Returns a user's total xp from their completed achievements.
  """
  def achievements_total_xp(course_id, course_reg_id) when is_ecto_id(course_id) do
    Logger.info(
      "Calculating total achievement XP for user #{course_reg_id} in course #{course_id}"
    )

    xp =
      Achievement
      |> join(:inner, [a], j in assoc(a, :goals))
      |> join(:inner, [_, j], g in assoc(j, :goal))
      |> join(:left, [_, _, g], p in GoalProgress,
        on: p.goal_uuid == g.uuid and p.course_reg_id == ^course_reg_id
      )
      |> where([a, j, g, p], a.course_id == ^course_id)
      |> group_by([a, j, g, p], a.uuid)
      |> having(
        [a, j, g, p],
        fragment(
          "bool_and(?)",
          p.completed and p.count == g.target_count and not is_nil(p.course_reg_id)
        )
      )
      # this max is a dummy - simply because a.xp is not under the GROUP BY
      |> select([a, j, g, p], %{
        xp: fragment("CASE WHEN bool_and(is_variable_xp) THEN SUM(count) ELSE MAX(xp) END")
      })
      |> subquery()
      |> select([s], sum(s.xp))
      |> Repo.one()
      |> decimal_to_integer()

    Logger.info("Calculated achievement XP for user #{course_reg_id}: #{xp}")
    xp
  end

  defp decimal_to_integer(decimal) do
    if Decimal.is_decimal(decimal) do
      Decimal.to_integer(decimal)
    else
      0
    end
  end

  @spec upsert(map()) :: {:ok, Achievement.t()} | {:error, {:bad_request, String.t()}}
  @doc """
  Inserts a new achievement, or updates it if it already exists.
  """
  def upsert(attrs) when is_map(attrs) do
    uuid = attrs[:uuid] || attrs["uuid"]
    Logger.info("Upserting achievement #{uuid}")

    # course_id not nil check is left to the changeset
    case uuid do
      nil ->
        Logger.error("Achievement upsert failed - no UUID specified")
        {:error, {:bad_request, "No UUID specified in Achievement"}}

      uuid ->
        Achievement
        |> preload([:prerequisites, :goals])
        |> Repo.get(uuid)
        |> (&(&1 || %Achievement{})).()
        |> Achievement.changeset(attrs)
        |> Repo.insert_or_update()
        |> case do
          result = {:ok, _} ->
            Logger.info("Successfully upserted achievement #{uuid}")
            result

          {:error, changeset} ->
            Logger.error(
              "Failed to upsert achievement #{uuid}: #{full_error_messages(changeset)}"
            )

            {:error, {:bad_request, full_error_messages(changeset)}}
        end
    end
  end

  @spec upsert_many([map()]) :: {:ok, [Achievement.t()]} | {:error, {:bad_request, String.t()}}
  def upsert_many(many_attrs) when is_list(many_attrs) do
    Repo.transaction(fn ->
      for attrs <- many_attrs do
        case upsert(attrs) do
          {:ok, achievement} -> achievement
          {:error, error} -> Repo.rollback(error)
        end
      end
    end)
  end

  @doc """
  Deletes an achievement.
  """
  @spec delete(Ecto.UUID.t()) ::
          :ok | {:error, {:not_found, String.t()}}
  def delete(uuid) when is_binary(uuid) do
    Logger.info("Deleting achievement #{uuid}")

    case Achievement
         |> where(uuid: ^uuid)
         |> Repo.delete_all() do
      {0, _} ->
        Logger.error("Cannot delete achievement #{uuid} - not found")
        {:error, {:not_found, "Achievement not found"}}

      {count, _} ->
        Logger.info("Successfully deleted achievement #{uuid} (#{count} records)")
        :ok
    end
  end
end
