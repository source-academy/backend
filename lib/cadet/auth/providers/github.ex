defmodule Cadet.Auth.Providers.GitHub do
  @moduledoc """
  Provides identity using GitHub OAuth.
  """
  alias Cadet.Auth.Provider

  @behaviour Provider

  @type config :: %{
          clients: %{},
          token_url: String.t(),
          user_api: String.t()
        }

  @spec authorise(config(), Provider.authorise_params()) ::
          {:ok, %{token: Provider.token(), username: String.t()}}
          | {:error, Provider.error(), String.t()}
  def authorise(config, %{
        code: code,
        client_id: client_id,
        redirect_uri: redirect_uri
      }) do
    token_headers = [
      {"Content-Type", "application/x-www-form-urlencoded"},
      {"Accept", "application/json"}
    ]

    token_url = config.token_url
    user_api = config.user_api

    with {:validate_client, {:ok, client_secret}} <-
           {:validate_client, Map.fetch(config.clients, client_id)},
         {:token_query, token_query} <-
           {:token_query,
            URI.encode_query(%{
              client_id: client_id,
              client_secret: client_secret,
              code: code,
              redirect_uri: redirect_uri
            })},
         {:token, {:ok, %{body: body, status_code: 200}}} <-
           {:token, HTTPoison.post(token_url, token_query, token_headers)},
         {:token_response, %{"access_token" => token}} <- {:token_response, Jason.decode!(body)},
         {:user, {:ok, %{"login" => username}}} <- {:user, api_call(user_api, token)} do
      {:ok, %{token: token, username: username}}
    else
      {:validate_client, :error} ->
        {:error, :invalid_credentials, "Invalid client id"}

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
  def get_name(config, token) do
    user_api = config.user_api

    case api_call(user_api, token) do
      {:ok, %{"name" => name}} ->
        {:ok, name}

      {:error, _, _} = error ->
        error
    end
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
