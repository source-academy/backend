defmodule Cadet.Accounts.Ivle do
  @moduledoc """
  Helper functions to IVLE calls. All helper functions are prefixed with fetch
  to differentiate them from database helpers, or other 'getters'.

  This module relies on the environment variable `IVLE_KEY` being set.
  `IVLE_KEY` should contain the IVLE Lapi key. Obtain the key from
  [this link](http://ivle.nus.edu.sg/LAPI/default.aspx).
  """

  @api_url "https://ivle.nus.edu.sg/api/Lapi.svc"
  @api_key Dotenv.load!().values["IVLE_KEY"]

  @doc """
  Get the NUSNET ID of the user corresponding to this token.

  returns...

    - {:ok, nusnet_id} - valid token, nusnet_id is a string
    - {:error, :bad_request} - invalid token
    - {:error, :internal_server_error} - the ivle_key is invalid

  ## Parameters

    - token: String, the IVLE authentication token

  ## Examples

      iex> Cadet.Accounts.Ivle.fetch_nusnet_id("T0K3N...")
      {:ok, "e012345"}

  """
  def fetch_nusnet_id(token), do: api_fetch("UserID_Get", token)

  @doc """
  Get the full name of the user corresponding to this token.

  returns...

    - {:ok, username} - valid token, username is a string
    - {:error, :bad_request} - invalid token
    - {:error, :internal_server_error} - the ivle_key is invalid

  ## Parameters

    - token: String, the IVLE authentication token

  ## Examples

      iex> Cadet.Accounts.Ivle.fetch_name("T0K3N...")
      {:ok, "LEE NING YUAN"}

  """
  def fetch_name(token), do: api_fetch("UserName_Get", token)

  defp api_fetch(path, token) do
    # IVLE responds with 200 (:ok) if key and token are valid
    # If key is invalid, IVLE responds with 500 (:internal_server_error)
    # If token is invalid, IVLE returns an 'empty' string (i.e. "\"\"")
    case HTTPoison.get(api_url(path, token)) do
      {:ok, response} ->
        if String.length(response.body) > 2 do
          {:ok, String.replace(response.body, ~s("), "")}
        else
          {:error, :bad_request}
        end

      {:error, _} ->
        {:error, :internal_server_error}
    end
  end

  defp api_url(path, token) do
    # construct a valid URL with the module attributes, and given params
    "#{@api_url}/#{path}?APIKey=#{@api_key}&Token=#{token}"
  end
end
