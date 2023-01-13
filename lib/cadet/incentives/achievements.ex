defmodule Cadet.Incentives.Achievements do
  @moduledoc """
  Stores `Achievement`s.
  """
  use Cadet, [:context, :display]

  alias Cadet.Incentives.{Achievement, GoalProgress}

  import Ecto.Query

  require Decimal

  @doc """
  Returns all achievements.

  Returns Achievement structs with prerequisites and goal association maps pre-loaded.
  """
  @spec get(integer()) :: [Achievement.t()]
  def get(course_id) when is_ecto_id(course_id) do
    Achievement
    |> where(course_id: ^course_id)
    |> preload([:prerequisites, :goals])
    |> Repo.all()
  end

  @doc """
  Returns a user's total xp from their completed achievements.
  """
  def achievements_total_xp(course_id, course_reg_id) when is_ecto_id(course_id) do
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
    # course_id not nil check is left to the changeset
    case attrs[:uuid] || attrs["uuid"] do
      nil ->
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
            result

          {:error, changeset} ->
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
    case Achievement
         |> where(uuid: ^uuid)
         |> Repo.delete_all() do
      {0, _} -> {:error, {:not_found, "Achievement not found"}}
      {_, _} -> :ok
    end
  end

  @doc """
  Returns a list of all total xp of all students in a course
  """
  @spec get_all_students_total_xp(integer()) :: list()
  def get_all_students_total_xp(course_id) when is_ecto_id(course_id) do
    combined_user_xp_total_query = """
    SELECT
      name,
      username,
      assessment_xp,
      achievement_xp
    FROM
      (SELECT
        sum(total_xp) as assessment_xp,
        users.name,
        users.username,
        total_xps.cr_id
      FROM
        (
          SELECT
            sum(sa1."xp") + sum(sa1."xp_adjustment") + max(ss0."xp_bonus") AS "total_xp",
            ss0."student_id" as cr_id,
            ss0.user_id
          FROM
            (
              SELECT
                submissions.xp_bonus,
                submissions.student_id,
                submissions.id,
                cr_ids.user_id
              FROM
                submissions
                INNER JOIN (
                  SELECT
                    cr.id as id,
                    cr.user_id
                  FROM
                    course_registrations cr
                  WHERE
                    cr.course_id = #{course_id}
                ) cr_ids on cr_ids.id = submissions.student_id
            ) as ss0
            INNER JOIN "answers" sa1 ON ss0."id" = sa1."submission_id"
          GROUP BY
            ss0."id",
            ss0."student_id",
            ss0."user_id"
        ) total_xps
        inner join users on users.id = total_xps.user_id
      GROUP BY
        username,
        cr_id,
        name) as total_assessments
    LEFT JOIN
      (SELECT
        sum(s0."xp") as achievement_xp,
        s0."course_reg_id" as cr_id
      FROM
        (
          SELECT
            CASE WHEN bool_and(is_variable_xp) THEN SUM(count) ELSE MAX(xp) END AS "xp",
            sg3."course_reg_id" AS "course_reg_id"
          FROM
            "achievements" AS sa0
            INNER JOIN "achievement_to_goal" AS sa1 ON sa1."achievement_uuid" = sa0."uuid"
            INNER JOIN "goals" AS sg2 ON sg2."uuid" = sa1."goal_uuid"
            RIGHT OUTER JOIN "goal_progress" AS sg3 ON (sg3."goal_uuid" = sg2."uuid")
          WHERE
            (sa0."course_id" = #{course_id})
          GROUP BY
            sa0."uuid",
            sg3."course_reg_id"
          HAVING
            (
              bool_and(
                (
                  sg3."completed"
                  AND (sg3."count" >= sg2."target_count")
                )
                AND NOT (sg3."course_reg_id" IS NULL)
              )
            )
        ) AS s0
      GROUP BY s0."course_reg_id") as total_achievement
    ON total_assessments."cr_id" = total_achievement."cr_id"
    """

    all_users_total_xp = Ecto.Adapters.SQL.query!(Repo, combined_user_xp_total_query)
    all_users_total_xp.rows
  end
end
