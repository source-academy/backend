defmodule Cadet.Auth.Providers.GitHub do
  @moduledoc """
  Provides identity using GitHub OAuth.
  """
  alias Cadet.Auth.Provider

  @behaviour Provider

  @type config :: %{client_secret: String.t()}

  @token_url "https://github.com/login/oauth/access_token"
  @user_api "https://api.github.com/user"

  @spec authorise(config(), Provider.code(), Provider.client_id(), Provider.redirect_uri()) ::
          {:ok, %{token: Provider.token(), username: String.t()}}
          | {:error, Provider.error(), String.t()}
  def authorise(config, code, client_id, redirect_uri) do
    token_query =
      URI.encode_query(%{
        client_id: client_id,
        client_secret: config.client_secret,
        code: code,
        redirect_uri: redirect_uri
      })

    token_headers = [
      {"Content-Type", "application/x-www-form-urlencoded"},
      {"Accept", "application/json"}
    ]

    with {:token, {:ok, %{body: body, status_code: 200}}} <-
           {:token, HTTPoison.post(@token_url, token_query, token_headers)},
         {:token_response, %{"access_token" => token}} <- {:token_response, Jason.decode!(body)},
         {:user, {:ok, %{"login" => username}}} <- {:user, api_call(@user_api, token)} do
      {:ok, %{token: token, username: Provider.namespace(username, "github")}}
    else
      {:token, {:ok, %{status_code: status}}} ->
        {:error, :upstream, "Status code #{status} from GitHub"}

      {:token_response, %{"error" => error}} ->
        {:error, :invalid_credentials, "Error from GitHub: #{error}"}

      {:user, {:error, _, _} = error} ->
        error
    end
  end

  @spec get_name(config(), Provider.token()) ::
          {:ok, String.t()} | {:error, Provider.error(), String.t()}
  def get_name(_, token) do
    case api_call(@user_api, token) do
      {:ok, %{"name" => name}} ->
        {:ok, name}

      {:error, _, _} = error ->
        error
    end
  end

  def get_role(_config, _claims) do
    # There is no role specified for the GitHub provider
    {:error, :invalid_credentials, "No role specified in token"}
  end

  defp api_call(url, token) do
    headers = [{"Authorization", "token " <> token}]

    case HTTPoison.get(url, headers) do
      {:ok, %{body: body, status_code: 200}} ->
        {:ok, Jason.decode!(body)}

      {:ok, %{status_code: status}} ->
        {:error, :upstream, "Status code #{status} from GitHub"}
    end
  end
end
