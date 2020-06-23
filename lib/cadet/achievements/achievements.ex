defmodule Cadet.Achievements do
  @moduledoc """
  The Achievement entity stores metadata of a students' assessment
  """
  
  use Cadet, [:context, :display]

  alias Cadet.Achievements.Achievement

  import Ecto.Query

  def all_achievements() do
    Achievement.Repo.all 
  end 

  def update_achievements(new_achievements) do 
    from(old_achievement in Achievement, where: old_achievement.xp >= 0) |> Cadet.Repo.delete_all

    for new_achievement <- new_achievements do
      Cadet.Repo.insert(:achievement, new_achievement)
    end 
  end 
end

