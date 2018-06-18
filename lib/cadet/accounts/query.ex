defmodule Cadet.Accounts.Query do
  @moduledoc """
  Generate queries related to the Accounts context
  """
  import Ecto.Query

  alias Cadet.Accounts.Authorization

  def user_nusnet_ids(user_id) do
    Authorization
    |> nusnet_ids
    |> of_user(user_id)
  end

  def nusnet_id(uid) do
    Authorization
    |> nusnet_ids
    |> of_uid(uid)
  end

  defp nusnet_ids(query) do
    query |> where([a], a.provider == "nusnet_id")
  end

  defp of_user(query, user_id) do
    query |> where([a], a.user_id == ^user_id)
  end

  defp of_uid(query, uid) do
    query |> where([a], a.uid == ^uid)
  end
end
