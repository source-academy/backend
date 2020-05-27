defmodule Cadet.Auth.Providers.Config do
  @moduledoc """
  Provides identity using configuration.

  The configuration should be a list of users in the following format:

  ```
  [%{code: "code1", token: "token1", username: "Username", name: "Name", role: :student}]
  ```

  This is mainly meant for test and development use.
  """

  alias Cadet.Auth.Provider

  @behaviour Provider

  @spec authorise(any(), Provider.code(), Provider.client_id(), Provider.redirect_uri()) ::
          {:ok, %{token: Provider.token(), username: String.t()}}
          | {:error, Provider.error(), String.t()}
  def authorise(config, code, _client_id, _redirect_uri) do
    case Enum.find(config, nil, fn %{code: this_code} -> code == this_code end) do
      %{token: token, username: username} -> {:ok, %{token: token, username: username}}
      _ -> {:error, :invalid_credentials, "Invalid code"}
    end
  end

  @spec get_name(any(), Provider.token()) ::
          {:ok, String.t()} | {:error, Provider.error(), String.t()}
  def get_name(config, token) do
    case Enum.find(config, nil, fn %{token: this_token} -> token == this_token end) do
      %{name: name} -> {:ok, name}
      _ -> {:error, :invalid_credentials, "Invalid token"}
    end
  end

  @spec get_role(any(), Provider.token()) ::
          {:ok, Cadet.Accounts.Role.t()} | {:error, Provider.error(), String.t()}
  def get_role(config, token) do
    case Enum.find(config, nil, fn %{token: this_token} -> token == this_token end) do
      %{role: role} -> {:ok, role}
      _ -> {:error, :invalid_credentials, "Invalid token"}
    end
  end
end
