defmodule Cadet.Auth.Provider do
  @moduledoc """
  An identity provider, which takes the OAuth2 authentication code and exchanges
  it for a token with the OAuth2 provider, and then retrieves the user ID and name.
  """

  @type code :: String.t()
  @type token :: String.t()
  @type client_id :: String.t()
  @type redirect_uri :: String.t()
  @type error :: :upstream | :invalid_credentials | :other
  @type provider_instance :: String.t()
  @type username :: String.t()
  @type prefix :: String.t()

  @doc "Exchanges the OAuth2 authorisation code for a token and the user ID."
  @callback authorise(any(), code, client_id, redirect_uri) ::
              {:ok, %{token: token, username: String.t()}} | {:error, error(), String.t()}

  @doc "Retrieves the name of the user with the associated token."
  @callback get_name(any(), token) :: {:ok, String.t()} | {:error, error(), String.t()}

  @spec get_instance_config(provider_instance) :: {module(), any()} | nil
  def get_instance_config(instance) do
    Application.get_env(:cadet, :identity_providers, %{})[instance]
  end

  @spec authorise(provider_instance, code, client_id, redirect_uri) ::
          {:ok, %{token: token, username: String.t()}} | {:error, error(), String.t()}
  def authorise(instance, code, client_id, redirect_uri) do
    case get_instance_config(instance) do
      {provider, config} -> provider.authorise(config, code, client_id, redirect_uri)
      _ -> {:error, :other, "Invalid or nonexistent provider config"}
    end
  end

  @spec get_name(provider_instance, token) :: {:ok, String.t()} | {:error, error(), String.t()}
  def get_name(instance, token) do
    case get_instance_config(instance) do
      {provider, config} -> provider.get_name(config, token)
      _ -> {:error, :other, "Invalid or nonexistent provider config"}
    end
  end
end
