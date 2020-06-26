defmodule Cadet.Achievements do
  @moduledoc """
  The Achievement entity stores metadata of a students' assessment
  """
  
  use Cadet, [:context, :display]

  alias Cadet.Achievements.Achievement

  import Ecto.Query

  def all_achievements() do
    Cadet.Repo.all(Achievement)
  end 

  def update_achievements(new_achievements) do 
    Cadet.Repo.delete_all(Achievement)

    for new_achievement <- new_achievements do
      add_achievement(new_achievement)
    end 

    :ok
  end 

  def add_achievement(new_achievement) do 
    Cadet.Repo.insert(
      %Achievement{
        inferencer_id: new_achievement["id"], 
        title: new_achievement["title"],
        ability: new_achievement["ability"], 
        exp: new_achievement["exp"],
        is_task: new_achievement["isTask"], 
        prerequisite_ids: new_achievement["prerequisiteIds"], 
        goal: new_achievement["completionGoal"], 
        progress: new_achievement["completionProgress"], 
  
        modal_image_url: new_achievement["modal"]["modalImageUrl"], 
        description: new_achievement["modal"]["modalImageUrl"], 
        goal_text: new_achievement["modal"]["goalText"], 
        completion_text: new_achievement["modal"]["completionText"]
      }
    )

    :ok
  end 

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
          goal: new_achievement["completionGoal"], 
          progress: new_achievement["completionProgress"], 
    
          modal_image_url: new_achievement["modal"]["modalImageUrl"], 
          description: new_achievement["modal"]["modalImageUrl"], 
          goal_text: new_achievement["modal"]["goalText"], 
          completion_text: new_achievement["modal"]["completionText"]
        ]
      )

    :ok
  end 

  def delete_achievement(new_achievement) do
    from(achievement in Achievement, where: achievement.inferencer_id == ^new_achievement["id"])
      |> Cadet.Repo.delete_all
    :ok
  end 

end

