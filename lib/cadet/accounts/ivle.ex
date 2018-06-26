defmodule Cadet.Accounts.IVLE do
  @moduledoc """
  Helper functions to IVLE calls. All helper functions are prefixed with fetch
  to differentiate them from database helpers, or other 'getters'.

  This module relies on the environment variable `IVLE_KEY` being set.
  `IVLE_KEY` should contain the IVLE Lapi key. Obtain the key from
  [this link](http://ivle.nus.edu.sg/LAPI/default.aspx).
  """

  @api_url "https://ivle.nus.edu.sg/api/Lapi.svc/"
  @api_key Dotenv.load().values["IVLE_KEY"]

  @doc """
  Get the NUSNET ID of the user corresponding to this token.

  returns...

    - {:ok, nusnet_id} - valid token, nusnet_id is a string
    - {:error, :bad_request} - invalid token
    - {:error, :internal_server_error} - the ivle_key is invalid

  ## Parameters

    - token: String, the IVLE authentication token

  ## Examples

      iex> Cadet.Accounts.IVLE.fetch_nusnet_id("T0K3N...")
      {:ok, "e012345"}

  """
  def fetch_nusnet_id(token), do: api_fetch("UserID_Get", Token: token)

  @doc """
  Get the full name of the user corresponding to this token.

  returns...

    - {:ok, username} - valid token, username is a string
    - {:error, :bad_request} - invalid token
    - {:error, :internal_server_error} - the ivle_key is invalid

  ## Parameters

    - token: String, the IVLE authentication token

  ## Examples

      iex> Cadet.Accounts.IVLE.fetch_name("T0K3N...")
      {:ok, "LEE NING YUAN"}

  """
  def fetch_name(token), do: api_fetch("UserName_Get", Token: token)

  @doc """
  Get the role of the user corresponding to this token.

  returns...

    - {:ok, :student} - valid token, permission "S"
    - {:ok, :admin} - valid token, permission "O", "F"
    - {:ok, :staff} - valid token, permissions "M", "R"
    - {:error, :bad_request} - invalid token, or not taking the module

  This function assumes that inactive modules have an ID of 
  `"00000000-0000-0000-0000-000000000000"`, and that there is only one active
  module with the course code `"CS1101S"`. (So far, these assumptions have been
  true).

  "O" represents an owner, "F" a co-owner, "M" a manager, and "R" a read manager.
  #
  ## Parameters

    - token: String, the IVLE authentication token

  ## Examples

      iex> Cadet.Accounts.IVLE.fetch_role("T0K3N...")
      {:ok, :student}

  """
  def fetch_role(token) do
    {:ok, modules} = api_fetch("Modules", AuthToken: token, CourseID: "CS1101S")

    cs1101s =
      modules["Results"]
      |> Enum.filter(fn module ->
        module["CourseCode"] == "CS1101S" and
          module["ID"] != "00000000-0000-0000-0000-000000000000"
      end)
      |> List.first()

    case cs1101s do
      %{"Permission" => "S"} ->
        {:ok, :student}

      %{"Permission" => x} when x == "O" or x == "F" ->
        {:ok, :admin}

      %{"Permission" => x} when x == "M" or x == "R" ->
        {:ok, :staff}

      _ ->
        {:error, :bad_request}
    end
  end

  defp api_fetch(method, queries) do
    case HTTPoison.get(api_url(method, queries)) do
      {:ok, %{body: body, status_code: 200}} when body != ~s("") ->
        {:ok, Poison.decode!(body)}

      {:ok, %{status_code: 500}} ->
        # IVLE responds with 500 if APIKey is invalid
        {:error, :internal_server_error}

      {:ok, %{body: ~s(""), status_code: 200}} ->
        # IVLE responsed 200 with body == ~s("") if token is invalid
        {:error, :bad_request}
    end
  end

  # Construct a valid URL with the module attributes, and given params
  # token_param_key is specified as some api calls use ...&Token={token},
  # but other calls use ...&AuthToken={token}
  defp api_url(method, queries) do
    queries = [APIKey: @api_key] ++ queries

    url =
      @api_url
      |> URI.merge(method)
      |> (&"#{&1}?#{URI.encode_query(queries)}").()

    url
  end
end
