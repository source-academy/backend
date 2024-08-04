defmodule CadetWeb.Plugs.RateLimiter do
  import Plug.Conn
  require Logger

  @rate_limit 500
  # 24 hours in milliseconds
  @period 86_400_000

  def init(default), do: default

  # This must be put after the AssignCurrentUser plug
  def call(conn, _opts) do
    user_id = conn.assigns.current_user.id
    key = "user:#{user_id}"

    case ExRated.check_rate(key, @period, @rate_limit) do
      {:ok, count} ->
        Logger.info("Received request from user #{user_id} with count #{count}")
        conn

      {:error, limit} ->
        Logger.error("Rate limit of #{limit} exceeded for user #{user_id}")

        conn
        |> put_status(:too_many_requests)
        |> send_resp(:too_many_requests, "Rate limit exceeded")
        |> halt()
    end
  end
end
