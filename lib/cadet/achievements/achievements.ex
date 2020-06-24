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
      Cadet.Repo.insert(:achievement, new_achievement)
    end 

    :ok
  end 
end

