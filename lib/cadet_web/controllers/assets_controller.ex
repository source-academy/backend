defmodule CadetWeb.AssetsController do
  use CadetWeb, :controller

  use PhoenixSwagger

  def index(conn, _params = %{"key" => key}) do
    assets =
      ExAws.S3.list_objects("source-academy-assets", [prefix: key <> "/"])
      |> ExAws.stream!
      |> Enum.take(1500)
    render(conn, "index.json", assets: assets)
  end

end
