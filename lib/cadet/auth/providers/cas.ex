defmodule Cadet.Auth.Providers.CAS do
  @moduledoc """
  Provides identity using CAS Protocol.
  https://apereo.github.io/cas/6.5.x/protocol/CAS-Protocol.html
  """

  import SweetXml

  alias Cadet.Auth.Provider

  @behaviour Provider

  @type config :: %{service_validate_endpoint: String.t(), modules: %{}}

  @spec authorise(config(), Provider.authorise_params()) ::
          {:ok, %{token: Provider.token(), username: String.t()}}
          | {:error, Provider.error(), String.t()}
  def authorise(config, %{
        code: code,
        redirect_uri: redirect_uri
      }) do
    params = %{
      ticket: code,
      service: redirect_uri
    }

    with {:validate, {:ok, %{body: body, status_code: 200}}} <-
           {:validate, HTTPoison.get(config.service_validate_endpoint, [], params: params)},
         {:authentication_success, success_xml} when not is_nil(success_xml) <-
           {:authentication_success, authentication_success(body)},
         {:extract_username, username} <- {:extract_username, get_username(success_xml)} do
      {:ok, %{token: success_xml, username: username}}
    else
      {:validate, {:ok, %{body: body, status_code: status}}} ->
        {:error, :upstream, "Status code #{status} from CAS: #{body}"}

      {:authentication_success, nil} ->
        {:error, :upstream, "Authentication failure from CAS"}
    end
  end

  @spec get_name(config(), Provider.token()) ::
          {:ok, String.t()} | {:error, Provider.error(), String.t()}
  def get_name(_config, token) do
    name = get_username(token)
    {:ok, name}
  rescue
    _ ->
      {:error, :invalid_credentials, "Failed to retrieve user's name"}
  end

  defp authentication_success(xml) do
    xml
    |> xpath(~x"//cas:serviceResponse/cas:authenticationSuccess"e)
  end

  defp get_username(xml) do
    xml
    |> xpath(~x"//cas:user/text()"s)
  end
end
