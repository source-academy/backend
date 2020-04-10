defmodule Cadet.GameStates do
  import Ecto.Repo

  # currently in this module no error handling function
  # has been implemented yet

  # simply return the game states of the user
  def user_game_states(user) do
    user.game_states
  end

  # simply return the collectibles of the user, within a single map
  def user_collectibles(user) do
    user.game_states["collectibles"]
  end

  # simply return the collectibles of the user, within a single map
  def user_save_data(user) do
    user.game_states["save_data"]
  end

  def update_collectibles(pic_nickname, pic_name, user) do
    changeset =
      Ecto.Changeset.cast(user, %{game_states: %{collectibles: Map.put(user_collectibles(user), pic_nickname, pic_name),
      save_data: user_save_data(user)}},[:game_states])
      Cadet.Repo.update!(changeset)
  end

  def update_save_data(action_sequence, start_location, user) do
    changeset =
    Ecto.Changeset.cast(user, %{game_states: %{collectibles: user_collectibles(user),
      save_data: %{
      action_sequence: action_sequence,
      start_location: start_location
    }}},[:game_states])
    Cadet.Repo.update!(changeset)
  end

  # functions below are for debugging and testing purposes
  def clear_up(user) do
    changeset =
      Ecto.Changeset.cast(user, %{game_states: %{collectibles: %{},
      save_data: %{action_sequence: [], start_location: ""}}},[:game_states])
    Cadet.Repo.update!(changeset)
  end

  def delete_all_collectibles(user) do
    changeset =
    Ecto.Changeset.cast(user, %{game_states: %{collectibles: %{}, save_data: user_save_data(user)}},[:game_states])
    Cadet.Repo.update!(changeset)
  end

  def delete_save_data(user) do
    changeset =
      Ecto.Changeset.cast(user, %{game_states: %{collectibles: user_collectibles(user),
      save_data: %{action_sequence: [], start_location: ""}}},[:game_states])
    Cadet.Repo.update!(changeset)
  end

end
