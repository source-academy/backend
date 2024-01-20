defmodule CadetWeb.AnswerView do
  use CadetWeb, :view

  def render("lastModified.json", %{lastModified: lastModified}) do
    %{
      lastModified: lastModified
    }
  end
end
