defmodule Cadet.Chat do
  @moduledoc """
  Contains logic to supplement ChatKit, an external service engaged for Source Academy.
  ChatKit's API can be found here: https://pusher.com/docs/chatkit
  """
  @instance_id :cadet |> Application.fetch_env!(:chat) |> Keyword.get(:instance_id)
  @key_id :cadet |> Application.fetch_env!(:chat) |> Keyword.get(:key_id)
  @key_secret :cadet |> Application.fetch_env!(:chat) |> Keyword.get(:key_secret)
  @time_to_live 8400

  @doc """
  Generates new bearer token for connection to ChatKit's ChatManager.

  Returns {:ok, token} on success, otherwise {:error, error_message}
  """
  def get_token(username) do
    curr_time_epoch = DateTime.to_unix(DateTime.utc_now())

    payload = %{
      "instance" => @instance_id,
      "iss" => "api_keys/" <> @key_id,
      "exp" => curr_time_epoch + @time_to_live,
      "iat" => curr_time_epoch,
      "sub" => username
    }

    Joken.Signer.sign(
      payload,
      Joken.Signer.create("HS256", @key_secret)
    )
  end
end
