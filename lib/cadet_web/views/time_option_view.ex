defmodule CadetWeb.TimeOptionView do
  use CadetWeb, :view
  alias CadetWeb.TimeOptionView

  def render("index.json", %{time_options: time_options}) do
    %{data: render_many(time_options, TimeOptionView, "time_option.json")}
  end

  def render("show.json", %{time_option: time_option}) do
    %{data: render_one(time_option, TimeOptionView, "time_option.json")}
  end

  def render("time_option.json", %{time_option: time_option}) do
    %{
      id: time_option.id,
      minutes: time_option.minutes,
      is_default: time_option.is_default
    }
  end
end
