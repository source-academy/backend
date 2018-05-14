defmodule CadetWeb.SessionController do
  use CadetWeb, :controller

  import Ecto.Changeset

  use PhoenixSwagger

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

  def logout(conn, _params) do
    conn
    |> Guardian.Plug.sign_out()
    |> redirect(to: session_path(conn, :new))
  end

  swagger_path :create do
    post "/session"
    summary "Authenticate user"
    consumes "application/json"
    parameters do
      login :body, Schema.ref(:FormLogin), "login attributes"
    end
    response 200, "OK"
    response 403, "Wrong login attributes"
  end

  def swagger_definitions do
    %{
      FormLogin: swagger_schema do
        title "Login form"
        description "Authentication"
        properties do
          email :string, "Email of user", required: true
          password :string, "Password of user", required: true
        end
      end
    }
  end

  defp flash_message(:create, reason) do
    case reason do
      :not_found -> "E-mail not registered in the system"
      :invalid_password -> "Invalid e-mail or password"
    end
  end
end
