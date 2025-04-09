defmodule Cadet.FocusLogs do
  @moduledoc """
  Contains logic to manage user's browser focus log
  such as insertion
  """
  alias Cadet.FocusLogs.FocusLog

  use Cadet, [:context, :display]

  def insert_log(user_id, course_id, focus_type) do
    insert_result =
      %FocusLog{}
      |> FocusLog.changeset(%{
        user_id: user_id,
        course_id: course_id,
        time: DateTime.utc_now(),
        focus_type: focus_type
      })
      |> Repo.insert()

    case insert_result do
      {:ok, log} -> {:ok, log}
      {:error, changeset} -> {:error, full_error_messages(changeset)}
    end
  end
end
