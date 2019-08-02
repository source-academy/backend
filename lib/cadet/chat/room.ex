defmodule Cadet.Chat.Room do
  @moduledoc """
  Contains logic pertaining to chatroom creation to supplement ChatKit, an external service engaged for Source Academy.
  ChatKit's API can be found here: https://pusher.com/docs/chatkit
  """

  require Logger

  alias Cadet.Repo
  alias Cadet.Assessments.{Answer, Submission}
  alias Cadet.Accounts.User
  alias Cadet.Chat.Token

  @instance_id (if Mix.env() != :test do
                  :cadet |> Application.fetch_env!(:chat) |> Keyword.get(:instance_id)
                else
                  "instance_id"
                end)

  @doc """
  Creates a chatroom for every answer, and updates db with the chatroom id.
  """
  def create_rooms(
        %Submission{
          assessment_id: assessment_id
        },
        answer = %Answer{question_id: question_id, room_id: room_id},
        user
      ) do
    with true <- room_id == nil,
         {:ok, %{"id" => room_id}} <- create_room(assessment_id, question_id, user) do
      answer
      |> Answer.room_id_changeset(%{
        room_id: room_id
      })
      |> Repo.update()
    end
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

    {:ok, token} = Token.get_superuser_token()
    headers = [Authorization: "Bearer #{token}"]

    body =
      Poison.encode!(%{
        "name" => "#{nusnet_id}_#{assessment_id}_Q#{question_id}"
      })

    case HTTPoison.post(url, body, headers) do
      {:ok, %HTTPoison.Response{body: body, status_code: 201}} ->
        Poison.decode(body)

      {:ok, %HTTPoison.Response{body: body, status_code: status_code}} ->
        response_body = Poison.decode!(body)

        error_message =
          "Room creation failed: #{response_body["error"]}, " <>
            "#{response_body["error_description"]} (status code #{status_code}) " <>
            "[user_id: #{student_id}, assessment_id: #{assessment_id}, question_id: #{question_id}]"

        Logger.error(error_message)
        Sentry.capture_message(error_message)

        {:error, nil}

      {:error, %HTTPoison.Error{reason: error}} ->
        Logger.error("error: #{inspect(error, pretty: true)}")
        {:error, nil}
    end
  end
end
