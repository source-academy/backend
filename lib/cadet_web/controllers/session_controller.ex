defmodule CadetWeb.SessionController do
  use CadetWeb, :controller

  alias Cadet.Accounts
  alias Cadet.Accounts.Form

  def new(conn, _params) do
    changeset = Form.Login.changeset(%Form.Login{})

    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"login" => attrs}) do
    changeset = Form.Login.changeset(%Form.Login{}, attrs)

    if changeset.valid? do
      redirect(conn, to: page_path(conn, :index))
    else
      render(conn, "new.html", changeset: %{changeset | action: :insert})
    end
  end

  def delete(conn, _params) do
    redirect(conn, to: session_path(conn, :new))
  end
end
