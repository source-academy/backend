defmodule Cadet.Achievements do
  @moduledoc """
  The Achievement entity stores metadata of a students' assessment
  """
  use Cadet, [:context, :display]

  alias Cadet.Achievements.Achievement

  import Ecto.Query

  def all_achievements() do
    Cadet.Repo.all(from a in Achievement, order_by: a.inferencer_id)
  end 

  def update_achievements(new_achievements) do 
    Cadet.Repo.delete_all(Achievement)

    for new_achievement <- new_achievements do
      add_achievement(new_achievement)
    end 

    :ok
  end 

  # Adds a new Achievement to the table
  def add_achievement(new_achievement) do 
    Cadet.Repo.insert(
      %Achievement{
        inferencer_id: new_achievement["id"], 
        title: new_achievement["title"],
        ability: new_achievement["ability"], 
        background_image_url: new_achievement["backgroundImageUrl"], 
        exp: new_achievement["exp"],
        is_task: new_achievement["isTask"], 
        prerequisite_ids: new_achievement["prerequisiteIds"], 
        goal: new_achievement["completionGoal"], 
        progress: new_achievement["completionProgress"], 
        position: new_achievement["position"], 

        close_at: new_achievement["deadline"], 
        open_at: new_achievement["release"], 
  
        modal_image_url: new_achievement["modal"]["modalImageUrl"], 
        description: new_achievement["modal"]["description"], 
        goal_text: new_achievement["modal"]["goalText"], 
        completion_text: new_achievement["modal"]["completionText"]
      }
    )

    :ok
  end 

  # Updates an Exisitng Achievement to the table
  def update_achievement(new_achievement) do 
    from(achievement in Achievement, where: achievement.inferencer_id == ^new_achievement["id"])
      |>  Cadet.Repo.update_all(
        set: [
          inferencer_id: new_achievement["id"], 
          title: new_achievement["title"],
          background_image_url: new_achievement["backgroundImageUrl"], 
          ability: new_achievement["ability"], 
          exp: new_achievement["exp"],
          is_task: new_achievement["isTask"], 
          prerequisite_ids: new_achievement["prerequisiteIds"], 
          goal: new_achievement["completionGoal"], 
          progress: new_achievement["completionProgress"], 
          position: new_achievement["position"], 

          close_at: new_achievement["deadline"], 
          open_at: new_achievement["release"], 
    
          modal_image_url: new_achievement["modal"]["modalImageUrl"], 
          description: new_achievement["modal"]["description"], 
          goal_text: new_achievement["modal"]["goalText"], 
          completion_text: new_achievement["modal"]["completionText"]
        ]
      )

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

end