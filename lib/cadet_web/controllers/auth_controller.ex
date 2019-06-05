defmodule CadetWeb.AuthController do
  use CadetWeb, :controller
  use PhoenixSwagger

  import Ecto.Changeset

  alias Cadet.Accounts
  alias Cadet.Accounts.Form.Login
  alias Cadet.Accounts.{Luminus, User}
  alias Cadet.Auth.Guardian

  @doc """
  Receives a /login request with valid attributes (`Login form`).

  If the user is already registered in our database, simply return `Tokens`. If
  the user has not been registered before, register the user, then return the
  `Tokens`.
  """
  def create(conn, %{"login" => attrs}) do
    changeset = Login.changeset(%Login{}, attrs)

    with valid = changeset.valid?,
         {:changes, login} when valid <- {:changes, apply_changes(changeset)},
         {:fetch, {:ok, token}} <-
           {:fetch, Luminus.fetch_luminus_token(login.luminus_code)},
         {:fetch, {:ok, nusnet_id, name}} <- {:fetch, Luminus.fetch_details(token)},
         {:signin, {:ok, user}} <- {:signin, Accounts.sign_in(nusnet_id, name, token)} do
      render(conn, "token.json", generate_tokens(user))
    else
      {:changes, _} ->
        conn
        |> put_status(:bad_request)
        |> text("Missing parameter")

      {:fetch, {:error, reason}} ->
        # reason can be :bad_request or :internal_server_error
        conn
        |> put_status(reason)
        |> text("Unable to fetch NUSNET ID from LumiNUS.")

      {:signin, {:error, reason}} ->
        # reason can be :bad_request or :internal_server_error
        conn
        |> put_status(reason)
        |> text("Unable to retrieve user")
    end
  end

  @doc """
  Receives a /login request with invalid attributes.
  """
  def create(conn, _params) do
    send_resp(conn, :bad_request, "Missing parameter")
  end

  @doc """
  Receives a /refresh request with valid attribute.

  Exchanges the refresh_token with a new access_token.
  """
  def refresh(conn, %{"refresh_token" => refresh_token}) do
    # TODO: Refactor to use refresh after guardian_db > v1.1.0 is released.
    case Guardian.resource_from_token(refresh_token) do
      {:ok, user, %{"typ" => "refresh"}} ->
        render(conn, "token.json", generate_tokens(user))

      _ ->
        send_resp(conn, :unauthorized, "Invalid Token")
    end
  end

  @doc """
  Receives a /refresh request with invalid attributes.
  """
  def refresh(conn, _params) do
    send_resp(conn, :bad_request, "Missing parameter")
  end

  @doc """
  Receives a /logout request with valid attribute.
  """
  def logout(conn, %{"refresh_token" => refresh_token}) do
    case Guardian.decode_and_verify(refresh_token) do
      {:ok, _} ->
        Guardian.revoke(refresh_token)
        text(conn, "OK")

      {:error, _} ->
        send_resp(conn, :unauthorized, "Invalid Token")
    end
  end

  @doc """
  Receives a /logout request with invalid attributes.
  """
  def logout(conn, _params) do
    send_resp(conn, :bad_request, "Missing parameter")
  end

  @spec generate_tokens(%User{}) :: %{access_token: String.t(), refresh_token: String.t()}
  defp generate_tokens(user) do
    {:ok, access_token, _} =
      Guardian.encode_and_sign(user, %{}, token_type: "access", ttl: {1, :hour})

    {:ok, refresh_token, _} =
      Guardian.encode_and_sign(user, %{}, token_type: "refresh", ttl: {1, :week})

    %{access_token: access_token, refresh_token: refresh_token}
  end

  swagger_path :create do
    post("/auth")

    summary("Obtain access and refresh tokens to authenticate user.")

    description(
      "Get a set of access and refresh tokens, using the authentication token " <>
        "from LumiNUS. When accessing resources, pass the access token in the " <>
        "Authorization HTTP header using the Bearer schema: `Authorization: " <>
        "Bearer <token>`. The access token expires 1 hour after issuance while " <>
        "the refresh token expires 1 week after issuance. When access token " <>
        "expires, the refresh token can be used to obtain a new access token. "
    )

    consumes("application/json")
    produces("application/json")

    parameters do
      login(:body, Schema.ref(:FormLogin), "login attributes", required: true)
    end

    response(200, "OK", Schema.ref(:Tokens))
    response(400, "Missing or invalid parameter")
    response(500, "Internal server error")
  end

  swagger_path :refresh do
    post("/auth/refresh")
    summary("Obtain new access token after expiry of the old one through refresh token")
    consumes("application/json")
    produces("application/json")

    parameters do
      refresh_token(
        :body,
        Schema.ref(:RefreshToken),
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
                  luminus_code(:string, "LumiNUS Authorization Code", required: true)
                end
              end
            )
          end

          required(:login)

          example(%{
            login: %{
              luminus_code: "a28caaa2330ea656d3012403f00bcb1e"
            }
          })
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
        end
    }
  end
end
