defmodule CadetWeb.DevicesView do
  use CadetWeb, :view

  def render("index.json", %{registrations: registrations}) do
    render_many(registrations, CadetWeb.DevicesView, "show.json", as: :registration)
  end

  def render("show.json", %{registration: registration}) do
    %{
      id: registration.id,
      title: registration.title,
      type: registration.device.type,
      secret: registration.device.secret
    }
  end
end
