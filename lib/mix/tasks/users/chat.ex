defmodule Mix.Tasks.Cadet.Users.Chat do
  @moduledoc """
    Creates ChatKit accounts for all users in the database.
    User creation: https://pusher.com/docs/chatkit/reference/api-v3#create-a-user
    Status codes: https://pusher.com/docs/chatkit/reference/api-v3#response-and-error-codes

    Note: this task is to be run after `import`.
    Assumption: "admin" must already exist in the ChatKit instance.
  """
  use Mix.Task

  require Logger

  import Cadet.Chat
  import Mix.EctoSQL

  alias Cadet.Repo
  alias Cadet.Accounts.User

  @instance_id :cadet |> Application.fetch_env!(:chat) |> Keyword.get(:instance_id)

  def run(_args) do
    ensure_started(Repo, [])
    HTTPoison.start()

    url = "https://us1.pusherplatform.io/services/chatkit/v4/#{@instance_id}/users"

    {:ok, token} = get_superuser_token()
    headers = [Authorization: "Bearer #{token}"]

    User
    |> Repo.all()
    |> Enum.each(fn user ->
      body = Poison.encode!(%{"name" => user.name, "id" => to_string(user.id)})

      case HTTPoison.post(url, body, headers) do
        {:ok, %HTTPoison.Response{status_code: 201}} ->
          :ok

        {:ok, %HTTPoison.Response{body: body}} ->
          Logger.error("Unable to create user (name: #{user.name}, user_id: #{user.id})")
          Logger.error("error: #{Poison.decode!(body)["error_description"]}")

        {:error, %HTTPoison.Error{reason: error}} ->
          Logger.error("error: #{inspect(error, pretty: true)}")
      end
    end)
  end
end
