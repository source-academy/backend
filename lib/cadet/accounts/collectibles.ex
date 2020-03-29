defmodule Cadet.Collectibles do
  import Ecto.Query
  alias Cadet.Accounts.User
  alias Ecto.Multi

  def user_collectibles(user) do
    # simply return the collectibles of the user, within a single map
    user.collectibles
  end

  '''
  @spec update_collectibles(
          string(),
          string(),
          %User{}
        ) ::
          {:ok, nil}
          | {:error, {:unauthorized | :bad_request | :internal_server_error, String.t()}}
  '''

  def update_grading_info(pic_nickname, pic_name, user) do

  end
end
