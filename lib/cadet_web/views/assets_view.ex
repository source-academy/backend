defmodule CadetWeb.AssetsView do
  use CadetWeb, :view
  use Timex

  def render("index.json", %{assets: assets}) do
    render_many(assets, CadetWeb.AssetsView, "show.json", as: :asset)
  end

  def render("show.json", %{asset: asset}) do
    asset
  end
end
