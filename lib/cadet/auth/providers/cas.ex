defmodule Cadet.Auth.Providers.CAS do
  @moduledoc """
  Provides identity using CAS Protocol.
  https://apereo.github.io/cas/6.5.x/protocol/CAS-Protocol.html
  """

  alias Cadet.Auth.Provider

  @behaviour Provider

  @type config :: %{service_validate_endpoint: String.t(), modules: %{}}

  @spec authorise(config(), Provider.code(), Provider.client_id(), Provider.redirect_uri()) ::
          {:ok, %{token: Provider.token(), username: String.t()}}
          | {:error, Provider.error(), String.t()}
  def authorise(config, code, _client_id, redirect_uri) do
    params = %{
      ticket: code,
      service: redirect_uri
    }

    with {:validate, {:ok, %{body: body, status_code: 200}}} <-
           {:validate, HTTPoison.get(config.service_validate_endpoint, [], params: params)} do
        #  {:validation_response, data} <- {:validation_response, Jason.decode!(body)},
        #  {:extract_username, %{"name" => username}} <- {:extract_username, data} do
          IO.inspect(body)
      {:ok, %{token: body, username: "placeholder"}}
    else
      {:validate, {:ok, %{body: body, status_code: status}}} ->
        {:error, :upstream, "Status code #{status} from CAS: #{body}"}
    end
  end

  @spec get_name(config(), Provider.token()) ::
          {:ok, String.t()} | {:error, Provider.error(), String.t()}
  def get_name(_config, token) do
    %{"name" => name} = token
    {:ok, name}
  rescue
    _ ->
      {:error, :invalid_credentials, "Failed to retrieve user's name"}
  end
end
