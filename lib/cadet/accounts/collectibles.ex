defmodule Cadet.Collectibles do
  import Ecto.Query
  alias Cadet.Accounts.{Notifications, User}
  def add_user_collectibles(user = %User{}, pic_nickname, pic_name) do
    # add the collectibles to user.collectibles, and return user.collectibles
    Map.put(user.collectibles, pic_nickname, pic_name)
  end
  def user_collectibles(user = %User{}) do
    # simply return the collectibles of the user, within a single map
    user.collectibles
  end
end
