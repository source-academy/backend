defmodule CadetWeb.AdminAssetsView do
  use CadetWeb, :view
  use Timex

  def render("index.json", %{assets: assets}) do
    render_many(assets, CadetWeb.AdminAssetsView, "show.json", as: :asset)
  end

  def render("show.json", %{asset: asset}) do
    asset
  end

  def render("show.json", %{resp: resp}) do
    resp
  end
end
