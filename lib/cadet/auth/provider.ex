defmodule Cadet.Auth.Provider do
  @moduledoc """
  An identity provider, which takes the OAuth2 authentication code and exchanges
  it for a token with the OAuth2 provider, and then retrieves the user ID and name.
  """

  @type token :: String.t()
  @type error :: :upstream | :invalid_credentials | :other
  @type provider_instance :: String.t()
  @type username :: String.t()
  @type prefix :: String.t()
  @type authorise_params :: %{
          conn: Plug.Conn.t(),
          provider_instance: provider_instance,
          code: String.t() | nil,
          client_id: String.t() | nil,
          redirect_uri: String.t() | nil
        }

  @doc "Exchanges the OAuth2 authorisation code for a token and the user ID."
  @callback authorise(any(), authorise_params()) ::
              {:ok, %{token: token, username: String.t()}} | {:error, error(), String.t()}

  @doc "Retrieves the name of the user with the associated token."
  @callback get_name(any(), token) :: {:ok, String.t()} | {:error, error(), String.t()}

  @spec get_instance_config(provider_instance()) :: {module(), any()} | nil
  def get_instance_config(instance) do
    Application.get_env(:cadet, :identity_providers, %{})[instance]
  end

  @spec authorise(authorise_params) ::
          {:ok, %{token: token, username: String.t()}} | {:error, error(), String.t()}
  def authorise(
        params = %{
          provider_instance: instance
        }
      ) do
    case get_instance_config(instance) do
      {provider, config} -> provider.authorise(config, params)
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
