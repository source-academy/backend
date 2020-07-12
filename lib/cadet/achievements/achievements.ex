defmodule Cadet.Achievements do
  @moduledoc """
  The Achievement entity stores metadata of a students' assessment
  """
  use Cadet, [:context, :display]

  alias Cadet.Achievements.{Achievement, AchievementGoal}
  alias Cadet.Accounts.User 

  import Ecto.Query

  def filter_goal(user, achievement) do 
    AchievementGoal
      |> where([g], g.achievement_id == ^achievement.id)
      |> where([g], g.user_id == ^user.id)
      |> Repo.all()
  end 

  def all_achievements(user) do
    achievements = Achievement
      |> order_by([a], [a.inferencer_id])
      |> Repo.all()
      |> Repo.preload([goals: [:achievement, :user]])

    Enum.map((achievements), fn a ->
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
        goal_text: a.goal_text, 
        completion_text: a.completion_text, 

        goals: filter_goal(user, a)
      }
    end)
  end 

  def update_achievements(new_achievements) do 
    for new_achievement <- new_achievements do
      update_achievement(new_achievement)
    end 

    :ok
  end 

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

  # Adds a new Achievement to the table
  def add_achievement(new_achievement) do 
    Cadet.Repo.insert(
      %Achievement{
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
        goal_text: new_achievement["modal"]["goalText"], 
        completion_text: new_achievement["modal"]["completionText"]
      }
    )

    update_goals(new_achievement)
    :ok
  end 

  # Updates an Exisitng Achievement to the table
  def update_achievement(new_achievement) do 
    from(achievement in Achievement, where: achievement.inferencer_id == ^new_achievement["id"])
      |>  Cadet.Repo.update_all(
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
          goal_text: new_achievement["modal"]["goalText"], 
          completion_text: new_achievement["modal"]["completionText"]
        ]
      )

      update_goals(new_achievement)
    :ok
  end 
  
  def insert_or_update_achievement(new_achievement) do
    query = Repo.exists?(from u in Achievement, where: u.inferencer_id == ^new_achievement["id"])
    if query do 
      update_achievement(new_achievement)
    else 
      add_achievement(new_achievement)
    end 
  end 

  def delete_goal(goal, achievement) do
    this_achievement =  from(achievement in Achievement, where: achievement.inferencer_id == ^achievement["id"])
      |> Repo.one()

    from(a in AchievementGoal, where: a.achievement_id == ^this_achievement.id and a.goal_id == ^goal["goalId"])
      |> Repo.delete_all()

    :ok
  end 

  def update_goals(new_achievement) do 
    this_achievement =  from(achievement in Achievement, where: achievement.inferencer_id == ^new_achievement["id"])
      |> Repo.one()

    users = User
      |> Repo.all() 

    for goal <- new_achievement["goals"] do 
    
      for user <- users do 

        query = Repo.exists?(from a in AchievementGoal, where: a.goal_id == ^goal["goalId"] and a.achievement_id == ^this_achievement.id and a.user_id == ^user.id)

        if query do 

          from(a in AchievementGoal, where: a.goal_id == ^goal["goalId"] and a.achievement_id == ^this_achievement.id and a.user_id == ^user.id) 
            |> Cadet.Repo.update_all(set: [
              goal_id: goal["goalId"], 
              goal_text: goal["goalText"], 
              goal_progress: goal["goalProgress"], 
              goal_target: goal["goalTarget"], 
              achievement_id: this_achievement.id,
              user_id: user.id
            ])

        else 

          Cadet.Repo.insert(%AchievementGoal{
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

end