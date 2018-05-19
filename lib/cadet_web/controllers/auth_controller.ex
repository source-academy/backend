defmodule CadetWeb.AuthController do
  use CadetWeb, :controller

  import Ecto.Changeset

  use PhoenixSwagger

  alias Cadet.Accounts
  alias Cadet.Auth.Guardian
  alias Cadet.Accounts.Form

  def create(conn, %{"login" => attrs}) do
    changeset = Form.Login.changeset(%Form.Login{}, attrs)

    if changeset.valid? do
      login = apply_changes(changeset)

      case Accounts.sign_in(login.email, login.password) do
        {:ok, user} ->
          {:ok, access_token, _} =
            Guardian.encode_and_sign(user, %{}, token_type: "access", ttl: {1, :hour})

          {:ok, refresh_token, _} =
            Guardian.encode_and_sign(user, %{}, token_type: "refresh", ttl: {52, :weeks})

          conn
          |> render("token.json", access_token: access_token, refresh_token: refresh_token)

        {:error, reason} ->
          {:ok, resp} = Poison.encode(%{reason: reason})

          conn
          |> send_resp(403, "Wrong email and/or password")
      end
    else
      conn
      |> send_resp(404, "Missing parameters")
    end
  end

  def create(conn, _params) do
    conn
    |> send_resp(404, "Missing parameters")
  end

  swagger_path :create do
    post("/auth")
    summary("Obtain tokens to authenticate user")
    consumes("application/json")

    parameters do
      login(:body, Schema.ref(:FormLogin), "login attributes", required: true)
    end

    response(200, "OK", Schema.ref(:Token))
    response(403, "Wrong login attributes")
    response(404, "Missing parameters")
  end

  def swagger_definitions do
    %{
      FormLogin:
        swagger_schema do
          title("Login form")
          description("Authentication")

          properties do
            login(
              Schema.new do
                properties do
                  email(:string, "Email of user", required: true)
                  password(:string, "Password of user", required: true)
                end
              end
            )
          end

          required(:login)
        end,
      Token:
        swagger_schema do
          title("Token")

          properties do
            access_token(:string, "Access token with TTL of 1 hour")
            refresh_token(:string, "Refresh token with TTL of 1 year")
          end
        end
    }
  end
end
