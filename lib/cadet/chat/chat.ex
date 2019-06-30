defmodule Cadet.Chat do
  @moduledoc """
  Contains logic to supplement ChatKit, an external service engaged for Source Academy.
  ChatKit's API can be found here: https://pusher.com/docs/chatkit
  """

  require Logger

  import Ecto.Query

  alias Cadet.Repo
  alias Cadet.Assessments.{Answer, Submission}
  alias Cadet.Accounts.User

  @instance_id :cadet |> Application.fetch_env!(:chat) |> Keyword.get(:instance_id)
  @key_id :cadet |> Application.fetch_env!(:chat) |> Keyword.get(:key_id)
  @key_secret :cadet |> Application.fetch_env!(:chat) |> Keyword.get(:key_secret)
  @token_ttl 86_400

  @doc """
  Generates user token for connection to ChatKit's ChatManager.
  Returns {:ok, token, ttl}.
  """
  def get_user_token(%User{id: user_id}) do
    {:ok, token} = get_token(to_string(user_id))
    {:ok, token, @token_ttl}
  end

  @doc """
  Generates a token for user with admin rights to enable superuser permissions.
  Returns {:ok, token}
  """
  def get_superuser_token do
    get_token("admin", true)
  end

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

  defp get_token(user_id, su \\ false) when is_binary(user_id) do
    curr_time_epoch = DateTime.to_unix(DateTime.utc_now())

    payload = %{
      "instance" => @instance_id,
      "iss" => "api_keys/#{@key_id}",
      "exp" => curr_time_epoch + @token_ttl,
      "iat" => curr_time_epoch,
      "sub" => user_id,
      "su" => su
    }

    # Note: dialyzer says signing only returns {:ok, token}
    Joken.Signer.sign(
      payload,
      Joken.Signer.create("HS256", @key_secret)
    )
  end

  defp get_staff_admin_user_ids do
    User
    |> Repo.all()
    |> Enum.filter(fn user -> user.role == :staff or user.role == :admin end)
    |> Enum.map(fn user -> to_string(user.id) end)
  end
end
