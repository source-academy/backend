defmodule CadetWeb.LayoutViewTest do
  use CadetWeb.ConnCase, async: true

  import Phoenix.HTML, only: [safe_to_string: 1]

  alias CadetWeb.LayoutView

  setup_all do
    prepared_conn =
      build_conn()
      |> bypass_through(CadetWeb.Router)
      |> get("/")

    {:ok, prepared_conn: prepared_conn}
  end

  test "Render head for production env", state do
    result =
      state[:prepared_conn]
      |> LayoutView.env_head_content(:prod)
      |> Enum.map(&safe_to_string/1)
      |> Enum.join()

    assert result =~ ~s(css/app.css)
    assert result =~ ~s(js/app.js)
    assert result =~ ~s(js/vendor.js)
  end

  test "Render head for development env", state do
    result =
      state[:prepared_conn]
      |> LayoutView.env_head_content(:dev)
      |> Enum.map(&safe_to_string/1)
      |> Enum.join()

    # Good enough heuristic to check whether we are serving Webpack assets
    assert result =~ ~s(0.0.0.0)
  end
end
