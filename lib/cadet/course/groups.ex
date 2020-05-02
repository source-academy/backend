defmodule Cadet.Course.Groups do
  use Cadet, [:context, :display]

  import Cadet.Accounts

  alias Cadet.Accounts.User
  alias Cadet.Course.Group

  @get_overviews_role ~w(staff admin)a

  @doc """
  Returns a list of groups containing information on the each group's id, avenger name and group name
  """
  @type group_overview :: %{id: integer, avenger_name: String.t, name: String.t}

  @spec get_group_overviews(%User{}) :: [group_overview]
  def get_group_overviews(_user = %User{role: role}) do
    if role in @get_overviews_role do
      overviews =
        Group
        |> Repo.all()
        |> Enum.map(fn group_info -> get_group_info(group_info) end)
      {:ok, overviews}
    else
      {:error, {:unauthorized, "Unauthorized"}}
    end
  end

  defp get_group_info(group_info) do
    %{
      id: group_info.id,
      avenger_name: get_user(group_info.leader_id).name,
      name: group_info.name
    }
  end
end
