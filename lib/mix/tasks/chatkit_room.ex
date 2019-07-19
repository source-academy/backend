defmodule Mix.Tasks.Cadet.ChatkitRoom do
  @moduledoc """
    Creates ChatKit rooms for answers with empty comments in the database.
    Room creation: https://pusher.com/docs/chatkit/reference/api#create-a-room
    Status codes: https://pusher.com/docs/chatkit/reference/api#response-and-error-codes

    Note:
    - Task is to run daily
  """
  use Mix.Task

  import Ecto.Query

  alias Cadet.Repo
  alias Cadet.Assessments.Submission
  alias Cadet.Chat.Room

  def run(_args) do
    Mix.Task.run("app.start")

    Submission
    |> join(:inner, [s], a in assoc(s, :answers))
    |> join(:inner, [s], u in assoc(s, :student))
    |> preload([_, a, u], answers: a, student: u)
    |> where([_, a], is_nil(a.comment))
    |> Repo.all()
    |> Enum.each(fn submission ->
      Enum.each(submission.answers, fn answer ->
        Room.create_rooms(submission, answer, submission.student)
      end)
    end)
  end
end
