defmodule Cadet.Course.Query do
  import Ecto.Query

  alias Cadet.Accounts.User
  alias Cadet.Course.Group
  alias Cadet.Course.Material

  def group_members(staff = %User{}) do
    group_members(staff.id)
  end

  def group_members(staff_id) do
    Group
    |> where([g], g.leader_id == ^staff_id)
  end

  def material_folder_files(folder_id) do
    Material
    |> where([m], m.parent_id == ^folder_id)
  end
end
