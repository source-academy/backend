defmodule Cadet.Achievements.Achievement do
  @moduledoc """
  The Achievement entity stores metadata of a students' assessment
  """

  use Cadet, [:context, :display]

  alias Cadet.Achievements.Achievement

  import Ecto.Query

  def all_achievements() do
    Achievement.Repo.all 
  end 

  def add_achievement() do
    new_achievement -> 
      achievement
      |> Achievement.changeset()
      |> Repo.update 
  end 

  def edit_achievement(id, params) do 
    simple_update(
      Achievement, 
      id, 
      using: &Achievement.changeset, 
      params: params
    )
  end 

  def delete_achievement(id) do
    achievement = Repo.get(Achievement, id)
    Repo.delete(achievement)
  end 
end

