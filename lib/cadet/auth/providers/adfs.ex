defmodule Cadet.Auth.Providers.ADFS do
  @moduledoc """
  Provides identity using NUS ADFS.
  """

  alias Cadet.Auth.Provider

  @behaviour Provider

  @type config :: %{token_endpoint: String.t(), modules: %{}}

  @spec authorise(config(), Provider.authorise_params()) ::
          {:ok, %{token: Provider.token(), username: String.t()}}
          | {:error, Provider.error(), String.t()}
  def authorise(config, %{
        code: code,
        client_id: client_id,
        redirect_uri: redirect_uri
      }) do
    query =
      URI.encode_query(%{
        client_id: client_id,
        grant_type: "authorization_code",
        code: code,
        redirect_uri: redirect_uri
      })

    headers = [
      {"Content-Type", "application/x-www-form-urlencoded"}
    ]

    with {:token, {:ok, %{body: body, status_code: 200}}} <-
           {:token, HTTPoison.post(config.token_endpoint, query, headers)},
         {:token_response, %{"access_token" => token}} <- {:token_response, Jason.decode!(body)},
         {:jwt, %JOSE.JWT{fields: %{"SamAccountName" => username} = claims}} <-
           {:jwt, JOSE.JWT.peek(token)},
         {:verify_jwt, {:ok, _}} <-
           {:verify_jwt,
            Guardian.Token.Jwt.Verify.verify_claims(Cadet.Auth.EmptyGuardian, claims, nil)} do
      {:ok, %{token: token, username: username}}
    else
      {:token, {:ok, %{body: body, status_code: status}}} ->
        {:error, :upstream, "Status code #{status} from ADFS: #{body}"}

      {:token_response, %{"error" => error}} ->
        {:error, :invalid_credentials, "Error from ADFS: #{error}"}

      {:jwt, _} ->
        {:error, :invalid_credentials, "Could not retrieve username from token"}

      {:verify_jwt, _} ->
        {:error, :invalid_credentials, "Failed to verify token claims (token expired?)"}
    end
  end

  @spec get_name(config(), Provider.token()) ::
          {:ok, String.t()} | {:error, Provider.error(), String.t()}
  def get_name(_config, token) do
    %JOSE.JWT{fields: %{"displayName" => name}} = JOSE.JWT.peek(token)
    {:ok, name}
  rescue
    _ ->
      {:error, :invalid_credentials, "Failed to retrieve user's display name from token"}
  end
end
