defmodule Cadet.Accounts.Ivle do
  @moduledoc """
  Helper functions to IVLE calls. All helper functions are prefixed with fetch
  to differentiate them from database helpers, or other 'getters'.

  This module relies on the environment variable `IVLE_KEY` being set.
  `IVLE_KEY` should contain the IVLE Lapi key. Obtain the key from
  [this link](http://ivle.nus.edu.sg/LAPI/default.aspx).
  """

  @api_url "https://ivle.nus.edu.sg/api/Lapi.svc"
  @api_key System.get_env("IVLE_KEY")

  @doc """
  Get the NUSNET ID of the user corresponding to this token.

  ## Parameters

    - token: String, the IVLE authentication token

  ## Examples

      iex> Cadet.Accounts.Ivle.fetch_nusnet_id("T0K3N...")
      {:ok, "e012345"}

  """
  def fetch_nusnet_id(token) do
    case HTTPoison.get(api_url("UserID_Get", token)) do
      {:ok, response} ->
        if response.status_code == 200 do
          {:ok, String.replace(response.body, ~s("), "")}
        else
          {:error, :bad_request}
        end

      {:error, _} ->
        {:error, :bad_request}
    end
  end

  @doc """
  Get the full name of the user corresponding to this token.

  ## Parameters

    - token: String, the IVLE authentication token

  ## Examples

      iex> Cadet.Accounts.Ivle.fetch_name("T0K3N...")
      {:ok, "LEE NING YUAN"}

  """
  def fetch_name(token) do
    case HTTPoison.get(api_url("UserName_get", token)) do
      {:ok, response} ->
        if response.status_code == 200 do
          {:ok, String.replace(response.body, ~s("), "")}
        else
          {:error, :bad_request}
        end

      {:error, _} ->
        {:error, :bad_request}
    end
  end

  defp api_url(path, token) do
    # construct a valid URL with the module attributes, and given params
    "#{@api_url}/#{path}?APIKey=#{@api_key}&Token=#{token}"
  end
end
