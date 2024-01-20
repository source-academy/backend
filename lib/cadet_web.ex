# credo:disable-for-this-file Credo.Check.Consistency.MultiAliasImportRequireUse
defmodule CadetWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use CadetWeb, :controller
      use CadetWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  use ContextManager

  def controller do
    quote do
      use Phoenix.Controller, namespace: CadetWeb

      import Plug.Conn
      import CadetWeb.Router.Helpers
      import CadetWeb.{ControllerHelper, Gettext}
      import Cadet.SharedHelper
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/cadet_web/templates",
        namespace: CadetWeb

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_flash: 2, view_module: 1]

      # Use all HTML functionality (forms, tags, etc)
      # use Phoenix.HTML

      import CadetWeb.Router.Helpers
      import CadetWeb.{Gettext, ViewHelper}
    end
  end

  def router do
    quote do
      use Phoenix.Router

      import Plug.Conn
      import Phoenix.Controller
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import CadetWeb.Gettext
    end
  end
end
