defmodule Cadet.Course.Groups do
  use Cadet, [:context, :display]

  alias Cadet.Course.Group
  import Cadet.Accounts  

  def get_group_overviews() do
    Group
    |> Repo.all()
    |> Enum.map(fn group_info -> get_group_info(group_info) end)
  end

  defp get_group_info(group_info) do
    %{
      id: group_info.id, 
      avenger_name: get_user(group_info.leader_id).name,
      name: group_info.name
    }
  end
end
