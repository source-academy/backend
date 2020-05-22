defmodule Cadet.Accounts.GameStates do
  @moduledoc """
  An entity that stores user game state.
  """

  use Cadet, :context
  alias Cadet.Accounts.User

  @update_gamestate_roles ~w(student)a
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

  def update(user = %User{role: role}, new_game_states) do
    if role in @update_gamestate_roles do
      changeset = cast(user, %{game_states: new_game_states}, [:game_states])
      Repo.update!(changeset)
      {:ok, nil}
    else
      {:error, {:forbidden, "Please try again later."}}
    end
  end

  def clear(user = %User{role: role}) do
    if role in @update_gamestate_roles do
      changeset =
        cast(user, %{game_states: %{collectibles: %{}, completed_quests: []}}, [
          :game_states
        ])

      Repo.update!(changeset)
      {:ok, nil}
    else
      {:error, {:forbidden, "Please try again later."}}
    end
  end
end
