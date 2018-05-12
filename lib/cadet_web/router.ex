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
    plug(CadetWeb.Plug.AssignCurrentUser)
  end

  pipeline :ensure_auth do
    plug(Guardian.Plug.EnsureAuthenticated)
  end

  pipeline :ensure_admin_staff do
    plug(CadetWeb.Plug.EnsureRoles, %{roles: [:admin, :staff]})
  end

  # Public Pages
  scope "/", CadetWeb do
    pipe_through([:browser, :auth])

    resources("/session", SessionController, only: [:new, :create])
    get("/session/logout", SessionController, :logout)
  end

  # Authenticated Pages
  scope "/", CadetWeb do
    pipe_through([:browser, :auth, :ensure_auth])

    get("/", PageController, :index)
  end

  # Admin Pages
  scope "/admin", CadetWeb do
    pipe_through([:browser, :auth, :ensure_auth, :ensure_admin_staff])

    get("/", AdminController, :index)
  end

  # Other scopes may use custom stacks.
  # scope "/api", CadetWeb do
  #   pipe_through :api
  # end
end
