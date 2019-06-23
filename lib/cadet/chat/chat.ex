defmodule Cadet.Chat do
  @moduledoc """
  Contains logic to supplement ChatKit, an external service engaged for Source Academy.
  ChatKit's API can be found here: https://pusher.com/docs/chatkit
  """

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
  def get_superuser_token() do
    get_token("admin", true)
  end

  @doc """
  Generates a new token for connection to ChatKit's API.
  Returns {:ok, token} on success, otherwise {:error, error_message}
  Note: dialyzer says it will always be successful, so no error handling required
  """
  defp get_token(user_id, su \\ false) when is_binary(user_id) do
    curr_time_epoch = DateTime.to_unix(DateTime.utc_now())

    payload = %{
      "instance" => @instance_id,
      "iss" => "api_keys/" <> @key_id,
      "exp" => curr_time_epoch + @token_ttl,
      "iat" => curr_time_epoch,
      "sub" => user_id,
      "su" => su
    }

    Joken.Signer.sign(
      payload,
      Joken.Signer.create("HS256", @key_secret)
    )
  end
end
