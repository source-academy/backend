defmodule Mix.Tasks.Cadet.Room do
  @moduledoc """
    Run the Cadet server.
    Currently it is equivalent with `phx.server`
  """
  use Mix.Task

  require Logger

  import Cadet.Chat
  import Ecto.Query
  import Mix.EctoSQL

  alias Cadet.Repo
  alias Cadet.Assessments.{Answer, Submission}
  alias Cadet.Accounts.User

  @instance_id :cadet |> Application.fetch_env!(:chat) |> Keyword.get(:instance_id)

  def run(_args) do
    # can remove later
    ensure_started(Repo, [])

    Answer
    |> where(submission_id: 2)
    |> Repo.all()
    |> Enum.filter(fn answer -> answer.comment == "" or answer.comment == nil end)
    |> Enum.each(fn answer ->
      case create_room(answer) do
        {:ok, %{"id" => room_id}} ->
          answer
          |> Answer.grading_changeset(%{
            comment: room_id
          })
          |> Repo.update()
      end
    end)
  end

  defp create_room(%Answer{submission_id: sub_id, question_id: qns_id}) do
    HTTPoison.start()

    url = "https://us1.pusherplatform.io/services/chatkit/v4/#{@instance_id}/rooms"

    {:ok, token} = get_superuser_token()
    headers = [Authorization: "Bearer #{token}"]

    body =
      Poison.encode!(%{
        "name" =>
          "#{
            sub_id
            |> Integer.to_string()
            |> String.pad_leading(1, "0")
          }_Q#{
            qns_id
            |> Integer.to_string()
            |> String.pad_leading(1, "0")
          }",
        "private" => true,
        "user_ids" => get_staff_admin_user_ids() ++ get_student_id(sub_id)
      })

    case HTTPoison.post(url, body, headers) do
      {:ok, %HTTPoison.Response{body: body, status_code: 201}} ->
        Poison.decode(body)

      {:ok, %HTTPoison.Response{body: body}} ->
        IO.puts(body)
        :error

      {:error, %HTTPoison.Error{reason: error}} ->
        Logger.error("error: #{inspect(error, pretty: true)}")
        :error
    end
  end

  defp get_staff_admin_user_ids do
    User
    |> Repo.all()
    |> Enum.filter(fn user -> user.role == :staff or user.role == :admin end)
    |> Enum.map(fn user -> to_string(user.id) end)
  end

  defp get_student_id(submission_id) do
    %{student_id: student_id} =
      Submission
      |> where(id: ^submission_id)
      |> select([:student_id])
      |> Repo.one()

    [to_string(student_id)]
  end
end
