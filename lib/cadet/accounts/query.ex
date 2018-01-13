defmodule Cadet.Accounts.Query do
  import Ecto.Query

  alias Cadet.Accounts.Authorization

  def user_emails(user_id) do
    from(a in Authorization)
    |> emails
    |> of_user(user_id)
  end

  def email(uid) do
    from(a in Authorization)
    |> emails
    |> of_uid(uid)
  end

  defp emails(query) do
    query |> where([a], a.provider == "email")
  end

  defp of_user(query, user_id) do
    query |> where([a], a.user_id == ^user_id)
  end

  defp of_uid(query, uid) do
    query |> where([a], a.uid == ^uid)
  end
end
