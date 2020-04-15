defmodule Cadet.GameStates do
  import Ecto.Repo

  # currently in this module no error handling function
  # has been implemented yet

  def user_game_states(user) do
    user.game_states
  end

  def user_collectibles(user) do
    user.game_states["collectibles"]
  end

  def user_save_data(user) do
    user.game_states["completed_quests"]
  end

  def update(user, new_game_states) do
    changeset =
      Ecto.Changeset.cast(user, %{game_states:
      new_game_states},[:game_states])
    Cadet.Repo.update!(changeset)
    {:ok, nil}
  end

  def clear(user) do
    changeset =
      Ecto.Changeset.cast(user, %{game_states: %{collectibles: %{},
      completed_quests: []}},[:game_states])
    Cadet.Repo.update!(changeset)
    {:ok, nil}
  end
end
