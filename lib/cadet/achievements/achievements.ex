defmodule Cadet.Achievements do
  @moduledoc """
  The Achievement entity stores metadata of a students' assessment
  """
  use Cadet, [:context, :display]

  alias Cadet.Achievements.{Achievement, AchievementGoal}
  alias Cadet.Accounts.User

  import Ecto.Query

  @edit_all_assessment_roles ~w(staff admin)a

  # Gets all achieveemnts of a particular user
  def all_achievements(user) do
    achievements =
      Achievement
      |> order_by([a], [a.inferencer_id])
      |> join(:full, [a], g in AchievementGoal, on: a.id == g.achievement_id)
      |> where([a, g], g.user_id == ^user.id)

    distinct_achievements =
      achievements
      |> distinct([a, g], [a.inferencer_id])
      |> Repo.all()
      |> Repo.preload(goals: [:achievement, :user])

    Enum.map(distinct_achievements, fn a ->
      %{
        inferencer_id: a.inferencer_id,
        id: :id,
        title: a.title,
        ability: a.ability,
        open_at: a.open_at,
        close_at: a.close_at,
        is_task: a.is_task,
        prerequisite_ids: a.prerequisite_ids,
        position: a.position,
        background_image_url: a.background_image_url,
        modal_image_url: a.modal_image_url,
        description: a.description,
        completion_text: a.completion_text,
        goals: get_user_goals(achievements, a)
      }
    end)
  end

  # Deletes an achievement in the table
  def delete_achievement(user, inferencer_id) do
    if user.role in @edit_all_assessment_roles do
      this_achievement =
        Achievement
        |> where([a], a.inferencer_id == ^inferencer_id)
        |> Repo.one()

      goal_query =
        AchievementGoal
        |> where([a], a.achievement_id == ^this_achievement.id)

      goal_query
      |> Repo.delete_all()

      this_achievement
      |> Repo.delete_all()

      :ok
    else
      {:error, {:forbidden, "User is not permitted to edit achievements"}}
    end
  end

  # Inserts a new achievement, or updates it if it already exists
  def insert_or_update_achievement(user, attrs) do
    if user.role in @edit_all_assessment_roles do
      _achievement =
        Achievement
        |> where(inferencer_id: ^attrs.inferencer_id)
        |> Repo.one()
        |> case do
          nil ->
            Achievement.changeset(%Achievement{}, attrs)

          achievement ->
            Achievement.changeset(achievement, attrs)
        end
        |> Repo.insert_or_update()
    else
      {:error, {:forbidden, "User is not permitted to edit achievements"}}
    end
  end

  # Deletes a goal of an achievement
  def delete_goal(user, goal_id, inferencer_id) do
    if user.role in @edit_all_assessment_roles do
      this_achievement =
        Achievement
        |> where([a], a.inferencer_id == ^inferencer_id)
        |> Repo.one()

      goal_query =
        AchievementGoal
        |> where([a], a.achievement_id == ^this_achievement.id and a.goal_id == ^goal_id)

      goal_query
      |> Repo.delete_all()

      :ok
    else
      {:error, {:forbidden, "User is not permitted to edit achievements"}}
    end
  end

  # Update All the goals of that achievement
  def update_goals(user, attrs) do
    if user.role in @edit_all_assessment_roles do
      this_achievement =
        Achievement
        |> where([a], a.inferencer_id == ^attrs.inferencer_id)
        |> Repo.one()

      users =
        User
        |> Repo.all()

      for goal_json <- attrs.goals do
        goal_params = get_goal_params_from_json(goal_json)

        for user <- users do
          _achievement_goal =
            AchievementGoal
            |> where([a], a.goal_id == ^goal_params.goal_id)
            |> where([a], a.achievement_id == ^this_achievement.id)
            |> where([a], a.user_id == ^user.id)
            |> Repo.one()
            |> case do
              nil ->
                AchievementGoal.changeset(%AchievementGoal{}, goal_params)

              achievement_goal ->
                AchievementGoal.changeset(achievement_goal, goal_params)
            end
            |> Repo.insert_or_update()
        end
      end
    else
      {:error, {:forbidden, "User is not permitted to edit achievements"}}
    end
  end

  def get_achievement_params_from_json(json) do
    %{
      inferencer_id: json["id"],
      title: json["title"],
      ability: json["ability"],
      is_task: json["isTask"],
      prerequisite_ids: json["prerequisiteIds"],
      position: json["position"],
      background_image_url: json["backgroundImageUrl"],
      close_at: get_date(json["deadline"]),
      open_at: get_date(json["release"]),
      modal_image_url: json["modal"]["modalImageUrl"],
      description: json["modal"]["description"],
      completion_text: json["modal"]["completionText"],
      goals: json["goals"]
    }
  end

  def get_goal_params_from_json(json) do
    %{
      goal_id: json["goalId"],
      goal_text: json["goalText"],
      goal_progress: json["goalProgress"],
      goal_target: json["goalTarget"]
    }
  end

  # Helper functions to update goals for a newly adder user
  def add_new_user_goals(user) do
    sample_users =
      User
      |> where([u], u.role == "student")
      |> limit(1)
      |> Repo.all()

    for sample_user <- sample_users do
      achievement_goals =
        AchievementGoal
        |> where([g], g.user_id == ^sample_user.id)
        |> Repo.all()

      for goal <- achievement_goals do
        Repo.insert(%AchievementGoal{
          goal_id: goal.goal_id,
          goal_text: goal.goal_text,
          # TODO: Fix this to 0 for new users.
          goal_progress: goal.goal_progress,
          goal_target: goal.goal_target,
          achievement_id: goal.achievement_id,
          user_id: user.id
        })
      end
    end
  end

  # Helper functions to get the goals for that particular user
  def get_user_goals(goal_achievements, achievement) do
    user_goals =
      goal_achievements
      |> where([a, g], a.id == ^achievement.id)
      |> select([a, g], g)
      |> Repo.all()

    Enum.map(user_goals, fn goal ->
      %{
        goal_id: goal.goal_id,
        goal_text: goal.goal_text,
        goal_progress: goal.goal_progress,
        goal_target: goal.goal_target
      }
    end)
  end

  # Helper function to parse date for opening and closing times of the achievement
  def get_date(date) do
    # result = Elixir.Timex.Parse.DateTime.Parser.parse(date, "{ISO:Extended:Z}")
    result = Timex.parse(date, "{ISO:Extended:Z}")

    case result do
      {:ok, date} ->
        date
        |> DateTime.truncate(:second)

      {:error, {status, message}} ->
        {:error, {status, message}}
    end
  end
end
