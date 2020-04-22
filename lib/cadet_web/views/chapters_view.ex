defmodule CadetWeb.ChaptersView do
  use CadetWeb, :view

  def render("show.json", %{chapter: chapter}) do
    %{
      chapter: chapter
    }
  end
end
