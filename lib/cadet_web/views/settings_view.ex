defmodule CadetWeb.SettingsView do
  use CadetWeb, :view

  def render("show.json", %{sublanguage: sublanguage}) do
    %{
      sublanguage: transform_map_for_view(sublanguage, [:chapter, :variant])
    }
  end
end
