defmodule Cadet.Accounts.Luminus do
  @moduledoc """
  This module provides abstractions for various LumiNUS API calls.

  This module depends on the config variables
  `:luminus_api_key`, `luminus_client_secret`, `luminus_client_secret`,
  `luminus_redirect_url`, being set.

  `:luminus_api_key` can be obtained from https://luminus.portal.azure-api.net/
  """

  use Timex

  @api_key :cadet |> Application.fetch_env!(:luminus) |> Keyword.get(:api_key)
  @client_id :cadet |> Application.fetch_env!(:luminus) |> Keyword.get(:client_id)
  @client_secret :cadet |> Application.fetch_env!(:luminus) |> Keyword.get(:client_secret)
  @redirect_url :cadet |> Application.fetch_env!(:luminus) |> Keyword.get(:redirect_url)
  @module_code :cadet |> Application.fetch_env!(:module_code)
  @api_token_url "https://luminus.nus.edu.sg/v2/auth/connect/token"
  @api_url "https://luminus.azure-api.net/"

  @student_access %{
    "access_Full" => false,
    "access_Create" => false,
    "access_Read" => true,
    "access_Update" => false,
    "access_Delete" => false,
    "access_Settings_Read" => false,
    "access_Settings_Update" => false
  }

  @staff_access %{
    "access_Full" => false,
    "access_Settings_Read" => true
  }

  @admin_access %{
    "access_Full" => true,
    "access_Create" => true,
    "access_Read" => true,
    "access_Update" => true,
    "access_Delete" => true,
    "access_Settings_Read" => true,
    "access_Settings_Update" => true
  }

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

  def fetch_luminus_token!(code, default \\ "token") do
    {:ok, token} = fetch_luminus_token(code, default)
    token
  end

  def fetch_luminus_token(nil, default) do
    {:ok, default}
  end

  def fetch_luminus_token(code, _) do
    fetch_luminus_token(code)
  end

  def fetch_luminus_token(code) do
    queries =
      URI.encode_query(%{
        client_id: @client_id,
        client_secret: @client_secret,
        grant_type: "authorization_code",
        code: code,
        redirect_uri: @redirect_url
      })

    headers = [{"Content-type", "application/x-www-form-urlencoded"}]

    case HTTPoison.post(@api_token_url, queries, headers) do
      {:ok, %{body: body, status_code: 200}} ->
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
    - {:error, :bad_request} - invalid token or luminus_client_secret is invalid

  ## Parameters

    - token: String, the LumiNUS authentication token

  ## Examples

      iex> Cadet.Accounts.LumiNUS.fetch_details("T0K3N...")
      {:ok, "e012345", "LIOW JIA CHEN"}

  """
  def fetch_details(token) do
    case api_call("userv3/Profile", token: token) do
      {:ok, %{"userID" => nusnet_id, "userNameOriginal" => name}} -> {:ok, nusnet_id, name}
      _ -> {:error, :bad_request}
    end
  end

  @doc """
  Get the role of the user corresponding to this token.

  We check the end date of the module to ensure student is currently taking or teaching CS1101S
  Roles:
    student permission -> :student
    manager / read manager permissions -> :staff
    owner / co-owner -> :admin

  returns...

    - {:ok, :student} - valid token, has student permissions
    - {:ok, :staff} - valid token, has manager or read manager permissions
    - {:ok, :admin} - valid token, has owner or co-owner permissions
    - {:error, :forbidden} - valid token, user does not currently read cs1101s
    - {:error, :bad_request} - invalid token or luminus_client_secret is invalid

  ## Parameters

    - token: String, the LumiNUS authentication token

  ## Parameters

    - token: String, the LumiNUS authentication token

  ## Examples

      iex> Cadet.Accounts.Luminus.fetch_role("T0K3N...")
      {:ok, :student}
  """

  def fetch_role(token) do
    case api_call("modulev3", token: token) do
      {:ok, modules} ->
        parse_modules(modules)

      {:error, _} ->
        {:error, :bad_request}
    end
  end

  defp module_active?(end_date) do
    Timex.before?(Timex.now(), Timex.parse!(end_date, "{ISO:Extended}"))
  end

  defp parse_modules(modules) do
    cs1101s =
      modules["data"]
      |> Enum.find(fn module ->
        module["name"] == @module_code && module_active?(module["endDate"])
      end)

    case cs1101s do
      nil -> {:error, :forbidden}
      %{"access" => @admin_access} -> {:ok, :admin}
      %{"access" => @staff_access} -> {:ok, :staff}
      %{"access" => @student_access} -> {:ok, :student}
      _ -> {:error, :bad_request}
    end
  end

  @doc """
  Make an API call to LumiNUS API.

  returns...

    - {:ok, body} - valid token
    - {:error, :bad_request} - invalid token

  ## Parameters

    - method: String, the HTTP request method to use
    - queries: [Keyword], key-value pair of parameters to send

  """
  def api_call(method, queries \\ [], token: token) do
    headers = [{"Ocp-Apim-Subscription-Key", @api_key}, {"Authorization", "Bearer #{token}"}]

    case HTTPoison.get(api_url(method, queries), headers) do
      {:ok, %{body: body, status_code: 200}} ->
        {:ok, Jason.decode!(body)}

      {:ok, %{status_code: 500}} ->
        # LumiNUS responds with 500 if there is a server error
        {:error, :internal_server_error}

      {:ok, %{status_code: 401}} ->
        # LumiNUS responds with 401 if APIKey is invalid
        {:error, :bad_request}

      {:ok, %{status_code: 404}} ->
        # LumiNUS responds with 404 if method is invalid
        {:error, :bad_request}
    end
  end
end
