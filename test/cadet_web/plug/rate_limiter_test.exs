defmodule CadetWeb.Plugs.RateLimiterTest do
  use CadetWeb.ConnCase
  import Plug.Conn
  alias CadetWeb.Plugs.RateLimiter

  setup %{conn: conn} do
    ExRated.delete_bucket("user:1")
    # Mock user data，in application should be done by "assign_current_user" plug
    user = %{id: 1}
    conn = update_in(conn.assigns, &Map.put_new(&1, :current_user, user))
    {:ok, conn: conn}
  end

  test "init" do
    assert RateLimiter.init(%{}) == %{}
  end

  test "rate limit not exceeded", %{conn: conn} do
    conn = RateLimiter.call(conn, %{})

    assert conn.status != 429
  end

  test "rate limit exceeded", %{conn: conn} do
    # Simulate exceeding the rate limit
    for _ <- 1..RateLimiter.rate_limit() do
      conn = RateLimiter.call(conn, %{})
      assert conn.status != 429
    end

    conn = RateLimiter.call(conn, %{})
    assert conn.status == 429
    assert conn.resp_body == "Rate limit exceeded"
  end

  test "no user found in conn.assigns.current_user", %{conn: conn} do
    conn = put_in(conn.assigns.current_user, nil)

    conn = RateLimiter.call(conn, %{})

    assert conn.status != 429
    assert conn.resp_body == nil
  end
end
