defmodule Cadet.Achievements do
  @moduledoc """
  The Achievement entity stores metadata of a students' assessment
  """
  use Cadet, [:context, :display]

  alias Cadet.Achievements.{Achievement, AchievementGoal}
  alias Cadet.Accounts.User

  import Ecto.Query

  # Gets all achieveemnts of a particular user
  def all_achievements(user) do
    achievements =
      Achievement
      |> order_by([a], [a.inferencer_id])
      |> Repo.all()
      |> Repo.preload(goals: [:achievement, :user])

    Enum.map(achievements, fn a ->
      %{
        inferencer_id: a.inferencer_id,
        id: :id,
        title: a.title,
        ability: a.ability,
        exp: a.exp,
        open_at: a.open_at,
        close_at: a.close_at,
        is_task: a.is_task,
        prerequisite_ids: a.prerequisite_ids,
        position: a.position,
        background_image_url: a.background_image_url,
        modal_image_url: a.modal_image_url,
        description: a.description,
        completion_text: a.completion_text,
        goals: get_user_goals(user, a)
      }
    end)
  end

  def update_achievements(new_achievements) do
    for new_achievement <- new_achievements do
      update_achievement(new_achievement)
    end

    :ok
  end

  # Deletes an achievement in the table
  def delete_achievement(inferencer_id) do
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
  end

  # Adds a new Achievement to the table
  def add_achievement(new_achievement) do
    Repo.insert(%Achievement{
      inferencer_id: new_achievement["id"],
      title: new_achievement["title"],
      ability: new_achievement["ability"],
      exp: new_achievement["exp"],
      is_task: new_achievement["isTask"],
      prerequisite_ids: new_achievement["prerequisiteIds"],
      position: new_achievement["position"],
      background_image_url: new_achievement["backgroundImageUrl"],
      close_at: get_date(new_achievement["deadline"]),
      open_at: get_date(new_achievement["release"]),
      modal_image_url: new_achievement["modal"]["modalImageUrl"],
      description: new_achievement["modal"]["description"],
      completion_text: new_achievement["modal"]["completionText"]
    })

    update_goals(new_achievement)
    :ok
  end

  # Updates an Exisitng Achievement to the table
  def update_achievement(new_achievement) do
    Achievement
    |> where([a], a.inferencer_id == ^new_achievement["id"])
    |> Repo.update_all(
      set: [
        inferencer_id: new_achievement["id"],
        title: new_achievement["title"],
        ability: new_achievement["ability"],
        exp: new_achievement["exp"],
        is_task: new_achievement["isTask"],
        prerequisite_ids: new_achievement["prerequisiteIds"],
        position: new_achievement["position"],
        background_image_url: new_achievement["backgroundImageUrl"],
        close_at: new_achievement["deadline"],
        open_at: new_achievement["release"],
        modal_image_url: new_achievement["modal"]["modalImageUrl"],
        description: new_achievement["modal"]["description"],
        completion_text: new_achievement["modal"]["completionText"]
      ]
    )

    update_goals(new_achievement)
    :ok
  end

  # Inserts a new achievement, or updates it if it already exists
  def insert_or_update_achievement(new_achievement) do
    does_achievement_exist =
      Achievement
      |> where([a], a.inferencer_id == ^new_achievement["id"])
      |> Repo.exists?()

    if does_achievement_exist do
      update_achievement(new_achievement)
    else
      add_achievement(new_achievement)
    end
  end

  # Deletes a goal of an achievement
  def delete_goal(goal_id, inferencer_id) do
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
  end

  # Update All the goals of that achievement
  # NOTE: All achievements are assumed to be in the original table
  def update_goals(new_achievement) do
    this_achievement =
      Achievement
      |> where([a], a.inferencer_id == ^new_achievement["id"])
      |> Repo.one()

    users =
      User
      |> Repo.all()

    for goal <- new_achievement["goals"] do
      for user <- users do
        does_goal_and_user_exist =
          AchievementGoal
          |> where([a], a.goal_id == ^goal["goalId"])
          |> where([a], a.achievement_id == ^this_achievement.id)
          |> where([a], a.user_id == ^user.id)
          |> Repo.exists?()

        if does_goal_and_user_exist do
          AchievementGoal
          |> where([a], a.goal_id == ^goal["goalId"])
          |> where([a], a.achievement_id == ^this_achievement.id)
          |> where([a], a.user_id == ^user.id)
          |> Repo.update_all(
            set: [
              goal_id: goal["goalId"],
              goal_text: goal["goalText"],
              goal_progress: goal["goalProgress"],
              goal_target: goal["goalTarget"],
              achievement_id: this_achievement.id,
              user_id: user.id
            ]
          )
        else
          Repo.insert(%AchievementGoal{
            goal_id: goal["goalId"],
            goal_text: goal["goalText"],
            goal_progress: goal["goalProgress"],
            goal_target: goal["goalTarget"],
            achievement_id: this_achievement.id,
            user_id: user.id
          })
        end
      end
    end
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
  def get_user_goals(user, achievement) do
    AchievementGoal
    |> where([g], g.achievement_id == ^achievement.id)
    |> where([g], g.user_id == ^user.id)
    |> Repo.all()
  end

  # Helper function to parse date for opening and closing times of the achievement
  def get_date(date) do
    result = Elixir.Timex.Parse.DateTime.Parser.parse(date, "{ISO:Extended:Z}")

    case result do
      {:ok, date} ->
        date
        |> DateTime.truncate(:second)

      {:error, {status, message}} ->
        {:error, {status, message}}
    end
  end
end
