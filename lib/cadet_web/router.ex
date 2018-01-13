defmodule CadetWeb.Router do
  use CadetWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :auth do
    plug(Cadet.Auth.Pipeline)
  end

  pipeline :ensure_auth do
    plug(Guardian.Plug.EnsureAuthenticated)
  end

  # Public Pages
  scope "/", CadetWeb do
    pipe_through([:browser, :auth])

    resources("/session", SessionController, only: [:new, :create, :delete])
  end

  # Authenticated Pages
  scope "/", CadetWeb do
    pipe_through([:browser, :auth, :ensure_auth])

    get("/", PageController, :index)
  end

  # Other scopes may use custom stacks.
  # scope "/api", CadetWeb do
  #   pipe_through :api
  # end
end
