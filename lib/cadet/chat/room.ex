defmodule Cadet.Chat.Room do
  @moduledoc """
  Contains logic pertaining to chatroom creation to supplement ChatKit, an external service engaged for Source Academy.
  ChatKit's API can be found here: https://pusher.com/docs/chatkit
  """

  require Logger

  import Cadet.Chat.Token
  import Ecto.Query

  alias Cadet.Repo
  alias Cadet.Assessments.{Answer, Submission}
  alias Cadet.Accounts.User

  @instance_id :cadet |> Application.fetch_env!(:chat) |> Keyword.get(:instance_id)

  @doc """
  Creates a chatroom for every answer, and updates db with the chatroom id.
  Takes in Submission struct
  """
  def create_rooms(%Submission{
        id: id,
        student_id: student_id,
        assessment_id: assessment_id
      }) do
    student = User |> where(id: ^student_id) |> Repo.one()

    Answer
    |> where(submission_id: ^id)
    |> Repo.all()
    |> Enum.filter(fn answer -> answer.comment == "" or answer.comment == nil end)
    |> Enum.each(fn answer ->
      case create_room(assessment_id, answer.question_id, student) do
        {:ok, %{"id" => room_id}} ->
          answer
          |> Answer.grading_changeset(%{
            comment: room_id
          })
          |> Repo.update()
      end
    end)
  end

  defp create_room(
         assessment_id,
         question_id,
         %User{
           id: student_id,
           nusnet_id: nusnet_id
         }
       ) do
    HTTPoison.start()

    url = "https://us1.pusherplatform.io/services/chatkit/v4/#{@instance_id}/rooms"

    {:ok, token} = get_superuser_token()
    headers = [Authorization: "Bearer #{token}"]

    body =
      Poison.encode!(%{
        "name" => "#{nusnet_id}_#{assessment_id}_Q#{question_id}",
        "private" => true,
        "user_ids" => get_staff_admin_user_ids() ++ [to_string(student_id)]
      })

    case HTTPoison.post(url, body, headers) do
      {:ok, %HTTPoison.Response{body: body, status_code: 201}} ->
        Poison.decode(body)

      {:ok, _} ->
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
end
