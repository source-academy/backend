defmodule Cadet.GameStates do
  import Ecto.Repo

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
    # to do
    changeset =
      Ecto.Changeset.cast(user, %{game_states: %{collectibles: Map.put(user_collectibles(user), pic_nickname, pic_name),
      save_data: user_save_data(user)}},[:game_states])
      Cadet.Repo.update!(changeset)
      # really simple error handling action, to be further implemented
    '''
      with {:ok, _} <- Repo.update(changeset) do
          {:ok, nil}
      else
        {:error, _} ->
          {:error, {:internal_server_error, "Please try again later."}}
      end
      '''
  end

  # should be idle since we are not going to delete students' collectibles
  # but provide the function delete_collectibles here for future extension
  def delete_all_collectibles(user) do
    changeset =
    Ecto.Changeset.cast(user, %{game_states: %{collectibles: %{}, save_data: user_save_data(user)}},[:game_states])
    Cadet.Repo.update!(changeset)
  end

  '''
  # to implement when needed

  def update_save_data() do
  ... # to do the actual implementation
  end

  def delete_all_save_data() do
  ... # to do the actual implementation
  end

  '''

end
