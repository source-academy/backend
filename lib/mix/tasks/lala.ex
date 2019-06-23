defmodule Mix.Tasks.Cadet.Test do
  @moduledoc """
    Creates ChatKit accounts for all users in the database.
    User creation: https://pusher.com/docs/chatkit/reference/api-v3#create-a-user
    Status codes: https://pusher.com/docs/chatkit/reference/api-v3#response-and-error-codes
  """
  use Mix.Task

  import Cadet.Chat
  import Mix.EctoSQL

  alias Cadet.Repo
  alias Cadet.Accounts.User

  @instance_id :cadet |> Application.fetch_env!(:chat) |> Keyword.get(:instance_id)

  def run(_args) do
    ensure_started(Repo, [])

    url = "https://us1.pusherplatform.io/services/chatkit/v4/#{@instance_id}/users"

    {:ok, token} = get_superuser_token()
    headers = [Authorization: "Bearer #{token}"]

    HTTPoison.start()

    User
    |> Repo.all()
    |> Enum.each(fn user ->
      body = Poison.encode!(%{"name" => user.name, "id" => to_string(user.id)})

      case HTTPoison.post(url, body, headers) do
        {:ok, %HTTPoison.Response{status_code: 201}} ->
          :ok

        {:ok, %HTTPoison.Response{body: body}} ->
          IO.puts(
            "Error: #{Poison.decode!(body)["error_description"]} " <>
              "(name: #{user.name}, user_id: #{user.id})"
          )

        {:error, %HTTPoison.Error{reason: reason}} ->
          IO.inspect(reason)
      end
    end)
  end
end
