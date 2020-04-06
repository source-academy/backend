defmodule Cadet.Course.Groups do
  use Cadet, [:context, :display]

  alias Cadet.Course.Group
  import Cadet.Accounts  
  
  # Returns a map where the group names are the key and the value is
  # another map with "avengerName" and "id" as the key
  def get_group_info() do
    Repo.all(Group)
    |> Enum.reduce(%{}, fn group, map -> Map.put(map, group.name, map_group_info(group))end)
  end

  defp map_group_info(group) do
    %{"avengerName" => get_user(group.leader_id).name, "id" => group.id}
  end
end
