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

          render(conn, "token.json", access_token: access_token, refresh_token: refresh_token)

        {:error, _reason} ->
          send_resp(conn, :forbidden, "Wrong email and/or password")
      end
    else
      send_resp(conn, :bad_request, "Missing parameters")
    end
  end

  def create(conn, _params) do
    send_resp(conn, :bad_request, "Missing parameters")
  end

  def refresh(conn, %{"refresh_token" => refresh_token}) do
    case Guardian.exchange(refresh_token, "refresh", "access") do
      {:ok, {refresh_token, _}, {access_token, _}} ->
        render(conn, "token.json", access_token: access_token, refresh_token: refresh_token)

      {:error, _reason} ->
        send_resp(conn, :unauthorized, "Invalid Token")
    end
  end

  def refresh(conn, _params) do
    send_resp(conn, :bad_request, "Missing parameter(s)")
  end

  def logout(conn, %{"access_token" => access_token}) do
    case Guardian.decode_and_verify(access_token) do
      {:ok, _} ->
        Guardian.revoke(access_token)

        send_resp(conn, :ok, "OK")

      {:error, _} ->
        send_resp(conn, :unauthorized, "Invalid Token")
    end
  end

  def logout(conn, _params) do
    send_resp(conn, :bad_request, "Missing parameter(s)")
  end

  swagger_path :create do
    post("/auth")

    summary("Obtain access and refresh tokens to authenticate user.")

    description(
      "When accessing resources, pass the access token in the Authorization HTTP header using the Bearer schema: `Authorization: Bearer <token>`. The access token expires 1 hour after issuance while the refresh token expires 1 year after issuance. When access token expires, the refresh token can be used to obtain a new access token."
    )

    consumes("application/json")
    produces("application/json")

    parameters do
      login(:body, Schema.ref(:FormLogin), "login attributes", required: true)
    end

    response(200, "OK", Schema.ref(:Tokens))
    response(400, "Missing parameter(s)")
    response(403, "Wrong login attributes")
  end

  swagger_path :refresh do
    post("/auth/refresh")
    summary("Obtain new access token after expiry of the old one through refresh token")
    consumes("application/json")
    produces("application/json")

    parameters do
      refresh_token(
        :body,
        Schema.ref(:AccessToken),
        "refresh token obtained from /auth",
        required: true
      )
    end

    response(200, "OK", Schema.ref(:Tokens))
    response(400, "Missing parameter(s)")
    response(401, "Invalid refresh token")
  end

  swagger_path :logout do
    post("/auth/logout")
    summary("Logout and invalidate the tokens")
    consumes("application/json")

    parameters do
      tokens(:body, Schema.ref(:RefreshToken), "refresh token to be invalidated", required: true)
    end

    response(200, "OK")
    response(400, "Missing parameter(s)")
    response(401, "Invalid token")
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

          example(%{login: %{email: "TestAdmin@test.com", password: "password"}})
        end,
      Tokens:
        swagger_schema do
          title("Tokens")

          properties do
            access_token(:string, "Access token with TTL of 1 hour")
            refresh_token(:string, "Refresh token with TTL of 1 year")
          end
        end,
      RefreshToken:
        swagger_schema do
          title("Refresh Token")

          properties do
            refresh_token(:string, "Refresh token", required: true)
          end
        end,
      AccessToken:
        swagger_schema do
          title("Access Token")

          properties do
            access_token(:string, "Access token", required: true)
          end
        end
    }
  end
end
