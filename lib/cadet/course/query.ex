defmodule Cadet.Course.Query do
  import Ecto.Query

  alias Cadet.Accounts.User
  alias Cadet.Course.Group

  def group_members(staff = %User{}) do
    group_members(staff.id)
  end

  def group_members(staff_id) do
    from(g in Group)
    |> where([g], g.leader_id == ^staff_id)
  end
end
