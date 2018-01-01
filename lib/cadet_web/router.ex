defmodule CadetWeb.Router do
  use CadetWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  scope "/", CadetWeb do
    pipe_through(:browser)

    get("/", PageController, :index)
    resources("/session", SessionController, only: [:new, :create, :delete])
  end

  # Other scopes may use custom stacks.
  # scope "/api", CadetWeb do
  #   pipe_through :api
  # end
end
