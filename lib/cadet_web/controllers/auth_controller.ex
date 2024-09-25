defmodule CadetWeb.AuthController do
  @moduledoc """
  Handles user login and authentication.
  """
  use CadetWeb, :controller
  use PhoenixSwagger

  alias Cadet.Accounts
  alias Cadet.Accounts.User
  alias Cadet.Auth.{Guardian, Provider}

  @doc """
  Receives a /login request with valid attributes.

  If the user is already registered in our database, simply return `Tokens`. If
  the user has not been registered before, register the user, then return the
  `Tokens`.
  """
  def create(
        conn,
        params = %{
          "code" => code,
          "provider" => provider
        }
      ) do
    client_id = Map.get(params, "client_id")
    redirect_uri = Map.get(params, "redirect_uri")

    case create_user_and_tokens(%{
           conn: conn,
           provider_instance: provider,
           code: code,
           client_id: client_id,
           redirect_uri: redirect_uri
         }) do
      {:ok, tokens} ->
        render(conn, "token.json", tokens)

      conn ->
        conn
    end
  end

  def create(conn, _params) do
    send_resp(conn, :bad_request, "Missing parameter")
  end

  @doc """
  Callback URL which processes a SAML redirect from the Assertion Consumer Service (ACS).
  """
  def saml_redirect(
        conn,
        %{
          "provider" => provider
        }
      ) do
    case create_user_and_tokens(%{
           conn: conn,
           provider_instance: provider,
           code: nil,
           client_id: nil,
           redirect_uri: nil
         }) do
      {:ok, tokens} ->
        {_provider, %{client_redirect_url: client_redirect_url}} =
          Application.get_env(:cadet, :identity_providers, %{})[provider]

        encoded_tokens = tokens |> Jason.encode!()

        conn
        |> put_resp_cookie("jwts", encoded_tokens,
          domain: URI.new!(client_redirect_url).host,
          http_only: false
        )
        |> put_resp_header("location", URI.encode(client_redirect_url))
        |> send_resp(302, "")
        |> halt()

      conn ->
        conn
    end
  end

  def saml_redirect(conn, _params) do
    send_resp(conn, :bad_request, "Missing parameter")
  end

  @spec create_user_and_tokens(Provider.authorise_params()) ::
          {:ok, %{access_token: String.t(), refresh_token: String.t()}} | Plug.Conn.t()
  defp create_user_and_tokens(
         params = %{
           conn: conn,
           provider_instance: provider
         }
       ) do
    with {:authorise, {:ok, %{token: token, username: username}}} <-
           {:authorise, Provider.authorise(params)},
         {:signin, {:ok, user}} <- {:signin, Accounts.sign_in(username, token, provider)} do
      {:ok, generate_tokens(user)}
    else
      {:authorise, {:error, :upstream, reason}} ->
        conn
        |> put_status(:bad_request)
        |> text("Unable to retrieve token from authentication provider: #{reason}")

      {:authorise, {:error, :invalid_credentials, reason}} ->
        conn
        |> put_status(:bad_request)
        |> text("Unable to validate token: #{reason}")

      {:authorise, {:error, _, reason}} ->
        conn
        |> put_status(:internal_server_error)
        |> text("Unknown error: #{reason}")

      {:signin, {:error, status, reason}} ->
        # status can be :bad_request or :internal_server_error
        conn
        |> put_status(status)
        |> text("Unable to retrieve user: #{reason}")
    end
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
        send_resp(conn, :unauthorized, "Invalid refresh token")
    end
  end

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
        send_resp(conn, :unauthorized, "Invalid token")
    end
  end

  def logout(conn, _params) do
    send_resp(conn, :bad_request, "Missing parameter")
  end

  @spec generate_tokens(User.t()) :: %{access_token: String.t(), refresh_token: String.t()}
  defp generate_tokens(user) do
    {:ok, access_token, _} =
      Guardian.encode_and_sign(user, %{}, token_type: "access", ttl: {1, :hour})

    {:ok, refresh_token, _} =
      Guardian.encode_and_sign(user, %{}, token_type: "refresh", ttl: {1, :week})

    %{access_token: access_token, refresh_token: refresh_token}
  end

  swagger_path :create do
    post("/auth/login")

    summary("Obtain access and refresh tokens to authenticate user")

    description(
      "Get a set of access and refresh tokens, using the authentication code " <>
        "from the OAuth2 provider. When accessing resources, pass the access " <>
        "token in the Authorization HTTP header using the Bearer schema: " <>
        "`Authorization: Bearer <token>`."
    )

    consumes("application/json")
    produces("application/json")

    parameters do
      code(:query, :string, "OAuth2 code", required: true)
      provider(:query, :string, "OAuth2 provider ID", required: true)
      client_id(:query, :string, "OAuth2 client ID", required: false)
      redirect_uri(:query, :string, "OAuth2 redirect URI", required: false)
    end

    response(200, "OK", Schema.ref(:Tokens))
    response(400, "Missing or invalid parameters or credentials, or upstream error")
    response(500, "Internal server error")
  end

  swagger_path :refresh do
    post("/auth/refresh")
    summary("Obtain a new access token using a refresh token")
    consumes("application/json")
    produces("application/json")

    parameters do
      refresh_token(
        :body,
        Schema.ref(:RefreshToken),
        "Refresh token obtained from /auth/login",
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
      tokens(:body, Schema.ref(:RefreshToken), "Refresh token to be invalidated", required: true)
    end

    response(200, "OK")
    response(400, "Missing parameter(s)")
    response(401, "Invalid token")
  end

  swagger_path :saml_redirect do
    get("/auth/saml_redirect")

    summary(
      "SAML redirect endpoint after Assertion Consumer Service validation. Generates JWT tokens before redirecting again to the frontend."
    )

    response(302, "Found")
  end

  def swagger_definitions do
    %{
      Tokens:
        swagger_schema do
          title("Tokens")

          properties do
            access_token(:string, "Access token with TTL of 1 hour", required: true)
            refresh_token(:string, "Refresh token with TTL of 1 week", required: true)
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
