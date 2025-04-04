defmodule Cadet.FocusLogs do
  alias Cadet.FocusLogs.FocusLog

  use Cadet, [:context, :display]

  def insert_log(user_id, course_id, focus_type) do
    datetime = DateTime.utc_now() |> DateTime.to_naive()
    IO.puts(datetime)
    insert_result = %FocusLog{}
    |> FocusLog.changeset(%{
      user_id: user_id,
      course_id: course_id,
      time: datetime,
      focus_type: focus_type})
    |> Repo.insert()

    case insert_result do
      {:ok, log} -> {:ok, log}
      {:error, changeset} -> {:error, full_error_messages(changeset)}
    end
  end
end
