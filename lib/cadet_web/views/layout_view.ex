defmodule CadetWeb.LayoutView do
  use CadetWeb, :view

  import Phoenix.HTML.Tag, only: [tag: 2, content_tag: 3]

  @doc """
  Returns environment-specific HTML Head content.
  """
  def env_head_content(conn) do
    if Application.get_env(:cadet, :environment) == :dev do
      script_tag(webpack_entry_file())
    else
      [
        stylesheet_tag(static_path(conn, "/css/app.css")),
        script_tag(static_path(conn, "/js/vendor.js")),
        script_tag(static_path(conn, "/js/app.js"))
      ]
    end
  end

  defp script_tag(src) do
    content_tag(:script, "", src: src)
  end

  defp stylesheet_tag(href) do
    tag(:link, rel: "stylesheet", href: href)
  end

  defp webpack_entry_file do
    "http://#{webpack_host()}:#{webpack_port()}/#{webpack_entry()}.js"
  end

  defp webpack_host, do: System.get_env("CADET_HOST")
  defp webpack_port, do: System.get_env("CADET_WEBPACK_PORT")
  defp webpack_entry, do: System.get_env("CADET_WEBPACK_ENTRY")
end
