defmodule Cadet.Accounts.IVLE do
  @moduledoc """
  This module provides abstractions for various IVLE API calls.

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
  def fetch_nusnet_id(token), do: api_call("UserID_Get", Token: token)

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
  def fetch_name(token), do: api_call("UserName_Get", Token: token)

  @doc """
  Get the role of the user corresponding to this token.

  returns...

    - {:ok, :student} - valid token, permission "S"
    - {:ok, :admin} - valid token, permission "O", "F"
    - {:ok, :staff} - valid token, permissions "M", "R"
    - {:error, :bad_request} - invalid token, or not taking the module
    - {:error, :internal_server_error} - the ivle_key is invalid

  ## Parameters

    - token: String, the IVLE authentication token

  This function assumes that inactive modules have an ID of 
  `"00000000-0000-0000-0000-000000000000"`, and that there is only one active
  module with the course code `"CS1101S"`. (So far, these assumptions have been
  true).

  "O" represents an owner, "F" a co-owner, "M" a manager, and "R" a read manager.

  ## Parameters

    - token: String, the IVLE authentication token

  ## Examples

      iex> Cadet.Accounts.IVLE.fetch_role("T0K3N...")
      {:ok, :student}

  """
  def fetch_role(token) do
    {:ok, modules} = api_call("Modules", AuthToken: token, CourseID: "CS1101S")

    cs1101s =
      modules["Results"]
      |> Enum.find(fn module ->
        module["CourseCode"] == "CS1101S" and
          module["ID"] != "00000000-0000-0000-0000-000000000000"
      end)

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

  @doc """
  Make an API call to IVLE LAPI.

  returns...

    - {:ok, body} - valid token
    - {:error, :internal_server_error} - Invalid API key
    - {:error, :bad_request} - Invalid token

  ## Parameters

    - method: String, the HTTP request method to use
    - queries: [Keyword], key-value pair of parameters to send

  This method is valid for methods that return with a string "Invalid login!"
  in a JSON nested in the body. Refer to the next method `api_call/2` for
  methods that return a 200 with an empty string body on invalid tokens.
  """
  def api_call(method, queries) when method in ["Announcements"] do
    with {:ok, %{status_code: 200, body: body}} <- HTTPoison.get(api_url(method, queries)),
         body = Poison.decode!(body),
         %{"Comments" => "Valid login!"} <- body do
      {:ok, body["Results"]}
    else
      {:ok, %{status_code: 500}} ->
        # IVLE responds with 500 if APIKey is invalid
        {:error, :internal_server_error}

      %{"Comments" => "Invalid login!"} ->
        # IVLE response if AuthToken is invalid
        {:error, :bad_request}
    end
  end

  def api_call(method, queries) when method in ["Workbins"] do
    with {:ok, %{status_code: 200, body: body}} <- HTTPoison.get(api_url(method, queries)) do
      {:ok, List.first(Poison.decode!(body)["Results"])["Folders"]}
    else
      {:ok, %{status_code: 500}} ->
        # IVLE responds with 500 if APIKey is invalid
        {:error, :internal_server_error}

      %{"Comments" => "Invalid login!"} ->
        # IVLE response if AuthToken is invalid
        {:error, :bad_request}
    end
  end

  def api_call(method, queries) when method in ["Download"] do
    queries = [APIKey: @api_key] ++ queries ++ [target: "workbin"]

    download_url =
      "https://ivle.nus.edu.sg/api/"
      |> URI.merge("downloadfile.ashx")
      |> Map.put(:query, URI.encode_query(queries))
      |> URI.to_string()

    with {:ok, %{status_code: 200, body: body}} <- HTTPoison.get(download_url) do
      {:ok, body}
    else
      {:ok, %{status_code: 500}} ->
        # IVLE responds with 500 if APIKey is invalid
        {:error, :internal_server_error}

      %{"Comments" => "Invalid login!"} ->
        # IVLE response if AuthToken is invalid
        {:error, :bad_request}
    end
  end

  @doc """
  Make an API call to IVLE LAPI.

  returns...

    - {:ok, body} - valid token
    - {:error, :internal_server_error} - Invalid API key
    - {:error, :bad_request} - Invalid token

  ## Parameters

    - method: String, the HTTP request method to use
    - queries: [Keyword], key-value pair of parameters to send

  This method is valid for methods that return a 200 with an empty string body
  on invalid tokens. For methods that return with string "Invalid login!" in a
  JSON nested in the body, refer to the previous method api_call/2 with guard
  clause.
  """
  def api_call(method, queries) do
    case HTTPoison.get(api_url(method, queries)) do
      {:ok, %{body: body, status_code: 200}} when body != ~s("") ->
        {:ok, Poison.decode!(body)}

      {:ok, %{status_code: 500}} ->
        # IVLE responds with 500 if APIKey is invalid
        {:error, :internal_server_error}

      {:ok, %{body: ~s(""), status_code: 200}} ->
        # IVLE responds 200 with body == ~s("") if token is invalid
        {:error, :bad_request}
    end
  end

  # Construct a valid URL with the module attributes, and given params
  # The authentication token parameter must be provided explicitly rather than
  # provided implicitly by this function as some API calls use ...&Token={token},
  # while others use ...&AuthToken={token}
  defp api_url(method, queries) do
    queries = [APIKey: @api_key] ++ queries

    @api_url
    |> URI.merge(method)
    |> Map.put(:query, URI.encode_query(queries))
    |> URI.to_string()
  end
end
