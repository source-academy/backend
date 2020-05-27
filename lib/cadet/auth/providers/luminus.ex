defmodule Cadet.Auth.Providers.LumiNUS do
  @moduledoc """
  Provides identity using LumiNUS and NUS ADFS.
  """

  alias Cadet.Auth.Provider

  @behaviour Provider

  @type config :: %{api_key: String.t(), module_code: String.t()}

  @api_url "https://luminus.azure-api.net/"

  @spec authorise(config(), Provider.code(), Provider.client_id(), Provider.redirect_uri()) ::
          {:ok, %{token: Provider.token(), username: String.t()}}
          | {:error, Provider.error(), String.t()}
  def authorise(config, code, client_id, redirect_uri) do
    query =
      URI.encode_query(%{
        client_id: client_id,
        grant_type: "authorization_code",
        code: code,
        redirect_uri: redirect_uri
      })

    headers = [
      {"Content-Type", "application/x-www-form-urlencoded"},
      {"Ocp-Apim-Subscription-Key", config.api_key}
    ]

    with {:token, {:ok, %{body: body, status_code: 200}}} <-
           {:token, HTTPoison.post(api_url("login/adfstoken"), query, headers)},
         {:token_response, %{"access_token" => token}} <- {:token_response, Jason.decode!(body)},
         {:jwt, %JOSE.JWT{fields: %{"samAccountName" => username} = claims}} <-
           {:jwt, JOSE.JWT.peek(token)},
         {:verify_jwt, {:ok, _}} <-
           {:verify_jwt,
            Guardian.Token.Jwt.Verify.verify_claims(Cadet.Auth.EmptyGuardian, claims, nil)} do
      {:ok, %{token: token, username: username}}
    else
      {:token, {:ok, %{body: body, status_code: status}}} ->
        {:error, :upstream, "Status code #{status} from LumiNUS: #{body}"}

      {:token_response, %{"error" => error}} ->
        {:error, :invalid_credentials, "Error from LumiNUS/ADFS: #{error}"}

      {:jwt, _} ->
        {:error, :invalid_credentials, "Could not retrieve username from token"}

      {:verify_jwt, _} ->
        {:error, :invalid_credentials, "Failed to verify token claims (token expired?)"}
    end
  end

  @spec get_name(config(), Provider.token()) ::
          {:ok, String.t()} | {:error, Provider.error(), String.t()}
  def get_name(config, token) do
    case api_call("user/Profile", token, config.api_key) do
      {:ok, %{"userNameOriginal" => name}} ->
        {:ok, name}

      {:error, _, _} = error ->
        error
    end
  end

  @spec get_role(config(), Provider.token()) ::
          {:ok, Cadet.Accounts.Role.t()} | {:error, Provider.error(), String.t()}
  @doc """
  Get the role of the user corresponding to this token.

  Roles:

  - student permission -> :student
  - manager / read manager permissions -> :staff
  - owner / co-owner -> :admin

  ## Returns

  - `{:ok, :student}` - valid token, has student permissions
  - `{:ok, :staff}` - valid token, has manager or read manager permissions
  - `{:ok, :admin}` - valid token, has owner or co-owner permissions
  - `{:error, :invalid_credentials, "User is not part of module"}` - valid token
    but the user does not currently read the module
  - `{:error, :upstream, "Status code xxx from LumiNUS"}` - invalid token or
    luminus_client_secret is invalid

  ## Parameters

  - `token`: String, the OAuth2 token

  ## Examples

      iex> Cadet.Accounts.Luminus.fetch_role("T0K3N...")
      {:ok, :student}
  """
  def get_role(config, token) do
    case api_call("module", token, config.api_key) do
      {:ok, modules} ->
        parse_modules(modules, config.module_code)

      {:error, _, _} = error ->
        error
    end
  end

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

  defp parse_modules(modules, module_code) do
    cs1101s =
      modules["data"]
      |> Enum.find(fn module ->
        module["name"] == module_code && module_active?(module["endDate"])
      end)

    case cs1101s do
      nil -> {:error, :invalid_credentials, "User is not part of module"}
      %{"access" => @admin_access} -> {:ok, :admin}
      %{"access" => @staff_access} -> {:ok, :staff}
      %{"access" => @student_access} -> {:ok, :student}
      _ -> {:error, :other, "Unexpected access combination"}
    end
  end

  defp module_active?(end_date) do
    Timex.before?(Timex.now(), Timex.parse!(end_date, "{ISO:Extended}"))
  end

  defp api_call(method, token, api_key) do
    headers = [{"Ocp-Apim-Subscription-Key", api_key}, {"Authorization", "Bearer #{token}"}]
    options = [timeout: 10_000, recv_timeout: 10_000]

    case HTTPoison.get(api_url(method), headers, options) do
      {:ok, %{body: body, status_code: 200}} ->
        {:ok, Jason.decode!(body)}

      {:ok, %{status_code: status}} ->
        {:error, :upstream, "Status code #{status} from LumiNUS"}

        # LumiNUS responds with 500 if there is a server error
        # LumiNUS responds with 401 if APIKey is invalid
        # LumiNUS responds with 404 if method is invalid
    end
  end

  defp api_url(method) do
    @api_url
    |> URI.merge(method)
    |> URI.to_string()
  end
end
