defmodule Cadet.Achievements do
  @moduledoc """
  The Achievement entity stores metadata of a students' assessment
  """
  use Cadet, [:context, :display]

  alias Cadet.Achievements.{Achievement, AchievementGoal}

  import Ecto.Query

  def all_achievements() do
    Achievement
      |> order_by([a], [a.inferencer_id])
      |> Repo.all()
      |> Repo.preload([goals: [:achievement]])
  end 

  def update_achievements(new_achievements) do 
    Cadet.Repo.delete_all(Achievement)

    for new_achievement <- new_achievements do
      add_achievement(new_achievement)
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

  def update_goals(new_achievement) do 
    this_achievement =  from(achievement in Achievement, where: achievement.inferencer_id == ^new_achievement["id"])
      |> Repo.one()

    for goal <- new_achievement["goals"] do
      query = Repo.exists?(from a in AchievementGoal, where: a.goal_id == ^goal["goalId"] and a.achievement_id == ^this_achievement.id)
      if not query do 
      Cadet.Repo.insert(%AchievementGoal{
        goal_id: goal["goalId"], 
        goal_text: goal["goalText"], 
        goal_progress: goal["goalProgress"], 
        goal_target: goal["goalTarget"], 
        achievement_id: this_achievement.id
      })
      else 
      from(a in AchievementGoal, where: a.goal_id == ^goal["goalId"] and a.achievement_id == ^this_achievement.id)
        |> Cadet.Repo.update_all(set: [
          goal_id: goal["goalId"], 
          goal_text: goal["goalText"], 
          goal_progress: goal["goalProgress"], 
          goal_target: goal["goalTarget"], 
          achievement_id: this_achievement.id
        ])
      end 
    end 
  end 

end