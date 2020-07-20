defmodule Cadet.Achievements do
  @moduledoc """
  The Achievement entity stores metadata of a students' assessment
  """
  use Cadet, [:context, :display]

  alias Cadet.Achievements.{Achievement, AchievementGoal}

  alias Cadet.Accounts.User

  import Ecto.Query

  @edit_all_achievement_roles ~w(staff admin)a

  @doc """
  Gets a user's achievements.

  This returns Achievement structs with prerequisites and goals pre-loaded. The
  goals also have the user's progress record loaded, if it exists.
  """
  @spec get_user_achievements(%User{}) :: [%Achievement{}]
  def get_user_achievements(user = %User{}) do
    Achievement
    |> order_by([a], [a.id])
    |> join(:left, [a], g in assoc(a, :goals))
    |> join(:left, [a, g], p in assoc(g, :progress))
    |> where([a, g, p], p.user_id == ^user.id or is_nil(p.user_id))
    |> preload([a, g, p], [:prerequisites, goals: {g, progress: p}])
    |> Repo.all()
  end

  @spec insert_or_update_achievement(%User{}, map()) ::
          {:ok, %Achievement{}} | {:error, {:bad_request | :forbidden, String.t()}}
  @doc """
  Inserts a new achievement, or updates it if it already exists.
  """
  def insert_or_update_achievement(user = %User{}, attrs) do
    if user.role in @edit_all_achievement_roles do
      attrs = stringify_atom_keys_recursive(attrs)
      id = Map.fetch!(attrs, "id")

      attrs =
        attrs
        |> fixup_achievement_goals(id)
        |> fixup_achievement_prerequisites(id)

      Achievement
      |> preload([a], [:prerequisites])
      |> Repo.get(id)
      |> case do
        nil ->
          Achievement.changeset(%Achievement{}, attrs)

        achievement ->
          # Preload only the goals that are going to be updated
          # (This is a no-op if inserting)
          orders = get_goal_orders(attrs)

          achievement =
            Repo.preload(achievement, goals: AchievementGoal |> where([g], g.order in ^orders))

          attrs = fixup_achievement_goal_ids(attrs, achievement)

          Achievement.changeset(achievement, attrs)
      end
      |> Repo.insert_or_update()
      |> case do
        result = {:ok, _} ->
          result

        {:error, changeset} ->
          {:error, {:bad_request, full_error_messages(changeset)}}
      end
    else
      {:error, {:forbidden, "User is not permitted to edit achievements"}}
    end
  end

  defp get_goal_orders(attrs) do
    for goal <- Map.get(attrs, "goals") || [],
        order = Map.get(goal, "order"),
        do: order
  end

  # Fix the primary keys of any goals passed in, if updating an achievement
  # This is to let Ecto automagically update already-existing matching goals
  defp fixup_achievement_goal_ids(attrs = %{"goals" => goals}, achievement) do
    # we need to assign the correct primary key IDs into the goals in attrs
    # so that Ecto automatically updates the associated goals for us
    # this is also a no-op if inserting
    order_to_pk = for goal <- achievement.goals, into: %{}, do: {goal.order, goal.id}

    new_goals =
      Enum.map(goals, fn goal ->
        goal
        |> Map.put("achievement_id", achievement.id)
        |> case do
          goal = %{"order" => order} -> assign_goal_primary_key(order_to_pk, goal, order)
          # if no order, let it pass through; Ecto will mark the changeset
          # as invalid
          goal -> goal
        end
      end)

    %{attrs | "goals" => new_goals}
  end

  defp fixup_achievement_goal_ids(attrs, _), do: attrs

  defp assign_goal_primary_key(map, goal, order) do
    case Map.get(map, order) do
      # order not in map means creating new goal, let it pass through
      nil -> goal
      id -> Map.put(goal, "id", id)
    end
  end

  # Set the achievement ID on any goals passed in
  defp fixup_achievement_goals(
         attrs = %{"goals" => goals},
         achievement_id
       ) do
    new_goals =
      for goal <- goals do
        Map.put(goal, "achievement_id", achievement_id)
      end

    %{attrs | "goals" => new_goals}
  end

  defp fixup_achievement_goals(attrs, _), do: attrs

  # Set the achievement ID on any prerequisites passed in
  # Also convert any bare IDs into prerequisites maps
  defp fixup_achievement_prerequisites(
         attrs = %{"prerequisites" => prerequisites},
         achievement_id
       ) do
    new_prerequisites =
      for prerequisite <- prerequisites do
        if is_ecto_id(prerequisite) do
          %{
            "achievement_id" => achievement_id,
            "prerequisite_id" => prerequisite
          }
        else
          prerequisite
          |> Map.put("achievement_id", achievement_id)
        end
      end

    %{attrs | "prerequisites" => new_prerequisites}
  end

  defp fixup_achievement_prerequisites(attrs, _), do: attrs

  @doc """
  Deletes an achievement.
  """
  @spec delete_achievement(%User{}, integer() | String.t()) ::
          :ok | {:error, {:not_found | :forbidden, String.t()}}
  def delete_achievement(user = %User{}, id) when is_ecto_id(id) do
    if user.role in @edit_all_achievement_roles do
      case Achievement
           |> where(id: ^id)
           |> Repo.delete_all() do
        {0, _} -> {:error, {:not_found, "Achievement not found"}}
        {_, _} -> :ok
      end
    else
      {:error, {:forbidden, "User is not permitted to edit achievements"}}
    end
  end

  @doc """
  Deletes a goal of an achievement.
  """
  @spec delete_goal(%User{}, integer() | String.t(), integer() | String.t()) ::
          :ok | {:error, {:not_found | :forbidden, String.t()}}
  def delete_goal(user, achievement_id, order) do
    if user.role in @edit_all_achievement_roles do
      case AchievementGoal
           |> where(achievement_id: ^achievement_id, order: ^order)
           |> Repo.delete_all() do
        {0, _} -> {:error, {:not_found, "Goal not found"}}
        {_, _} -> :ok
      end
    else
      {:error, {:forbidden, "User is not permitted to edit achievements"}}
    end
  end
end
