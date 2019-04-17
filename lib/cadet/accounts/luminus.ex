defmodule Cadet.Accounts.Luminus do
  @moduledoc """
  This module provides abstractions for various LumiNUS API calls.

  This module depends on the config variables
    `:luminus_api_key`, `luminus_client_secret`,  `luminus_client_secret`, `luminus_redirect_url`, being set.

  `:luminus_api_key` can be obtained from https://luminus.portal.azure-api.net/
  """

  @api_key :cadet |> Application.fetch_env!(:updater) |> Keyword.get(:luminus_api_key)
  @client_id :cadet |> Application.fetch_env!(:updater) |> Keyword.get(:luminus_client_id)
  @client_secret :cadet |> Application.fetch_env!(:updater) |> Keyword.get(:luminus_client_secret)
  @redirect_url :cadet |> Application.fetch_env!(:updater) |> Keyword.get(:luminus_redirect_url)
  @api_token_url "https://luminus.nus.edu.sg/v2/auth/connect/token"
  @api_url "https://luminus.azure-api.net/"

  # Construct a valid URL with the module attributes, and given params
  # The authentication token parameter must be provided explicitly rather than
  # provided implicitly by this function as some API calls use ...&Token={token},
  # while others use ...&AuthToken={token}
  defp api_url(method, queries) do
    @api_url
    |> URI.merge(method)
    |> Map.put(:query, URI.encode_query(queries))
    |> URI.to_string()
  end

  @doc """
  Exchange OAuth Authorization code for a valid access token.
  Token will expire in 30 minutes from the time it was issued.

  returns...

    - {:ok, :token} - valid token, token is a string
    - {:error, :bad_request} - invalid token
    - {:error, :internal_server_error} - the luminus_client_secret is invalid

  ## Parameters

    - code: String, the LumiNUS authorization code

  ## Examples

      iex> Cadet.Accounts.LumiNUS.fetch_luminus_token("C0dE...")
      {:ok, "12742174091894830298409823098098"}
  """

  def fetch_luminus_token(code) do
    queries =
      %{
        client_id: @client_id,
        client_secret: @client_secret,
        grant_type: "authorization_code",
        code: code,
        redirect_uri: @redirect_url
      }
      |> URI.encode_query()

    headers = [{"Content-type", "application/x-www-form-urlencoded"}]

    case HTTPoison.post(@api_token_url, queries, headers) do
      {:ok, %{body: body, status_code: 200}} when body != ~s("") ->
        {:ok, body |> Jason.decode!() |> Map.get("access_token")}

      {:ok, %{status_code: 400}} ->
        # LumiNUS responds with 400 if APIKey is invalid
        {:error, :bad_request}

    end
  end

  @doc """
  Get the NUSNET ID and the name of the user corresponding to this token.

  returns...

    - {:ok, nusnet_id, name} - valid token, nusnet_id are name are strings
    - {:error, :bad_request} - invalid token
    - {:error, :internal_server_error} - the luminus_client_secret is invalid

  ## Parameters

    - token: String, the LumiNUS authentication token

  ## Examples

      iex> Cadet.Accounts.LumiNUS.fetch_details("T0K3N...")
      {:ok, "e012345", "LIOW JIA CHEN"}

  """
  def fetch_details(token) do
    case api_call("user/Profile", Token: token) do
      {:ok, %{"userID" => nusnet_id, "userNameOriginal" => name}} -> {:ok, nusnet_id, name}
      _ -> {:error, :bad_request}
    end
  end

  @doc """
  Get the role of the user corresponding to this token.

  returns...

    - {:ok, :student} - valid token, access_Full set to true
    - {:ok, :admin} - valid token, access_Create set to true
    - {:ok, :staff} - valid token, access_Read set to true
    - {:error, :bad_request} - invalid token, or not taking the module
    - {:error, :internal_server_error} - the lumiNUS_client_secret is invalid

  ## Parameters

    - token: String, the LumiNUS authentication token

  This function assumes that inactive modules have an ID of
  `"00000000-0000-0000-0000-000000000000"`, and that there is only one active
  module with the course code `"CS1101S"`. (So far, these assumptions have been
  true).

  (^need to check if this is still a thing in lumiNUS)

  ## Parameters

    - token: String, the LumiNUS authentication token

  ## Examples

      iex> Cadet.Accounts.Luminus.fetch_role("T0K3N...")
      {:ok, :student}
  """

  def fetch_role(token) do
    case api_call("module", Token: token) do
      {:ok, modules} ->
        parse_modules(modules)

      {:error, _} ->
        {:error, :bad_request}
    end
  end

  defp parse_cs1101s(cs1101s) do
    {:ok, access} = cs1101s |> Map.fetch("access")

    case access do
      %{"access_Full" => true} ->
        {:ok, :admin}

      %{"access_Create" => true} ->
        {:ok, :staff}

      %{"access_Read" => true} ->
        {:ok, :student}

      _ ->
        {:error, :bad_request}
    end
  end

  defp parse_modules(modules) do
    cs1101s =
      modules["data"]
      |> Enum.find(fn module ->
        module["name"] == "CS1101S" and
          module["id"] != "00000000-0000-0000-0000-000000000000"
      end)

    case cs1101s do
      nil -> {:error, :bad_request}
      cs1101s -> parse_cs1101s(cs1101s)
    end
  end

  @doc """
  Make an API call to LumiNUS API.

  returns...

    - {:ok, body} - valid token
    - {:error, :internal_server_error} - Invalid API key
    - {:error, :bad_request} - Invalid token

  ## Parameters

    - method: String, the HTTP request method to use
    - queries: [Keyword], key-value pair of parameters to send

  """
  def api_call(method, queries \\ [], Token: token) do
    headers = [{'Ocp-Apim-Subscription-Key', @api_key}, {"Authorization", "Bearer #{token}"}]

    case HTTPoison.get(api_url(method, queries), headers) do
      {:ok, %{body: body, status_code: 200}} when body != ~s("") ->
        {:ok, Jason.decode!(body)}

      {:ok, %{status_code: 500}} ->
        # LumiNUS responds with 500 if APIKey is invalid
        {:error, :internal_server_error}

      {:ok, %{status_code: 401}} ->
        # LumiNUS responds with 401 if APIKey is invalid
        {:error, :bad_request}

      {:ok, %{status_code: 404}} ->
        # LumiNUS responds with 404 if APIKey is invalid
        {:error, :bad_request}

      {:ok, %{body: ~s(""), status_code: 200}} ->
        # LumiNUS responds 200 with body == ~s("") if token is invalid
        {:error, :bad_request}
    end
  end
end
