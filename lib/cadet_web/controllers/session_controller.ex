defmodule CadetWeb.SessionController do
  use CadetWeb, :controller

  import Ecto.Changeset

  alias Cadet.Accounts
  alias Cadet.Auth.Guardian
  alias Cadet.Accounts.Form

  def new(conn, _params) do
    changeset = Form.Login.changeset(%Form.Login{})

    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"login" => attrs}) do
    changeset = Form.Login.changeset(%Form.Login{}, attrs)

    if changeset.valid? do
      login = apply_changes(changeset)

      case Accounts.sign_in(login.email, login.password) do
        {:ok, user} ->
          conn
          |> Guardian.Plug.sign_in(user)
          |> redirect(to: page_path(conn, :index))

        {:error, reason} ->
          conn
          |> put_flash(:error, flash_message(:create, reason))
          |> redirect(to: session_path(conn, :new))
      end
    else
      render(conn, "new.html", changeset: %{changeset | action: :insert})
    end
  end

  def delete(conn, _params) do
    redirect(conn, to: session_path(conn, :new))
  end

  defp flash_message(:create, reason) do
    case reason do
      :not_found -> "E-mail not registered in the system"
      :invalid_password -> "Invalid e-mail or password"
      _ -> "Unknown"
    end
  end
end
