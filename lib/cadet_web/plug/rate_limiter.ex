defmodule CadetWeb.Plugs.RateLimiter do
  import Plug.Conn

  @rate_limit 500
  @period 86_400_000   # 24 hours in milliseconds

  def init(default), do: default

  # This must be put after the AssignCurrentUser plug
  def call(conn, _opts) do
    user_id = conn.assigns.current_user.id
    key = "user:#{user_id}"

    case ExRated.check_rate(key, @period, @rate_limit) do
      {:ok, _count} ->
        conn
      {:error, _limit} ->
        conn
        |> put_status(:too_many_requests)
        |> send_resp(:too_many_requests, "Rate limit exceeded")
        |> halt()
    end
  end
end
