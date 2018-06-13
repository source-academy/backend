defmodule Cadet.Accounts.Ivle do
  @moduledoc """
  Helper functions to IVLE calls. All helper functions are prefixed with fetch
  to differentiate them from database helpers, or other 'getters'.
  """

  @doc """
  Get the NUSNET ID of this token
  """
  def fetch_nusnet_id(token) do
    url = "https://ivle.nus.edu.sg/api/Lapi.svc/UserID_Get"
    key = System.get_env("IVLE_KEY")

    case HTTPoison.get("#{url}?APIKey=#{key}&Token=#{token}") do
      {:ok, response} ->
        if response.status_code == 200 do
          {:ok, String.replace(response.body, ~s("), "")}
        else
          {:error, response.status_code}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Get the name of this token
  """
  def fetch_name(token) do
    url = "https://ivle.nus.edu.sg/api/Lapi.svc/UserName_Get"
    key = System.get_env("IVLE_KEY")

    case HTTPoison.get("#{url}?APIKey=#{key}&Token=#{token}") do
      {:ok, response} ->
        if response.status_code == 200 do
          {:ok, String.replace(response.body, ~s("), "")}
        else
          {:error, response.status_code}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end
end
