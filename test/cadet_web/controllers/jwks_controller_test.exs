defmodule CadetWeb.JWKSControllerTest do
  use CadetWeb.ConnCase

  @test_jwk %{
    "p" =>
      "4jYjfgSj4dI2IvQ2NFe3Rr6q_BRcXRtFn-r2tJ8RcpuIzuAOa-gZU1XovJlUw4Cqpyc7ZkILfJQcVRl-hZO1v813Ez6TkZo7kMrWxEyaBH64V9aJAn1MxjyIMryWecgq3SGo-qWNhvZpU7rbgRuVf3jiga-rl8TNEK7NmX_yQ60",
    "kty" => "RSA",
    "q" =>
      "1AlvokTA71sl9cY44LM8dF1o59bDOsFEDIMQegc9aAYhngEnztUnatfhClkBQAcwG1wcm8mGa0qaj7KNC6N_SOK2QAGLCcVU6uAdeOLJDSOJVOQ0waZmLygjpIr3LR5luI3j2CWL19YxJGPs8Zzzyp2JSxeZ7LZWmXf8YX34ihM",
    "d" =>
      "WjLKemNCpGl3TI0h9rHTrsUkwiqXGzX_NUG1gLp_pT-BGuxPy-EtTZl8QVPX72juxzU9QsdMokr1JzpnVspxT3bUhvRbQD9grqwZmeHNKUmYCqA2keEUycdPYhTL4GoIyplC9oHwIPomRi2U9hEX3pYXKOUaLdSnI2AbSoDiWOgUjFpIs7MmhkNpJfmha4vo_sO_JyFMIbaXgRJsePwLRzDHrmKOqr0Bk4u9wT0Amoe3NiwI5y3R1mdOorO1LTk_HRPrhGp3gKO5KuHpO3w6daJPQdezvKrxMHEzSBu4r-9iYR3vFeytO_4mTOdNnpH_vMXUxKdpXKc1OR2nNnAZ0Q",
    "e" => "AQAB",
    "use" => "sig",
    "qi" =>
      "0srPgi_MTSp_ll5PHk8HEfWxBwN0trYjrBXP77v7hq3voFuUp1WXP0R3UWP3iCpGHW7RmwfBtnCXuEUX2du2mUg42HqR7qaocvCfjn09rvqEAlNYvn_RXt_TouRaLZKPL7SeSUe4gLyspXkLtZXnTUOyvuAteRoMeL4Loo55qsY",
    "dp" =>
      "Igsxxjpei5K-UP5d1fzJeV0ikHNj_yMmlE2hOUejMZNUwIWZxgWVIiSQtSmCRzXq-OL_noEcB3Cm3uvKTcIQHUCHxh6pyMTkaAMO1VYN69VCWv3Pes9uqXrcqH4XS1ajlMoHC0m1BfW5nj9F36VOF3QS6p-MfHfCwNr92DcYN7U",
    "alg" => "RS256",
    "dq" =>
      "Ptm1L2I11j0sWVeyUFiQmOV_TQlJwUa8RwEqhyFSQF1g5ZbuF87y6ianXAvZ5QK8bb-18y-fGnp4qhOA32xNNGuPHhXXAsRtUVmxIr4GXlCkSneCc8xBCcVaG1Hdxo_2EuhsGwu2Efo5gtHj0BJ36R0dLxcF1zaNINyCANv4KeU",
    "n" =>
      "u10r8Hes2BAxgy0WDYALK3tpZYjc4Ws0-qLKlI2T81XJAY2c-h33hNm7kn4rGJfAYvWy6ojdK8OgZrBCWcGm7C--SkzG_sWR3AttR9ZiE25pSlfvI793QHm4kyBb1DtXEclbJugFFjwiuyR9gZEDx1CFtlN4a77uyDevNGb9ufP2UiFb0-7OsIP_Oo_bt9NkeQXNtYqg5H7Xzhk1RBU2q_RzAdlEPkfen5-gdhUuScjCuR4yEwZJVqJK1xEh7h5l-HdEB_hGdcZHLKid0bagorvAI77dxEyGYyYibT5NboZ6ImIpPWifPzO27pT-Iui64UEExQiUqTtn0C-nIA5H1w"
  }

  test "returns public JWKs if Guardian secret is an asymmetric key map", %{conn: conn} do
    test_with_key(conn, @test_jwk)
  end

  test "returns public JWKs if Guardian secret is an asymmetric key JWK", %{conn: conn} do
    test_with_key(conn, JOSE.JWK.from_map(@test_jwk))
  end

  test "returns public JWKs if Guardian secret is a function", %{conn: conn} do
    test_with_key(conn, {__MODULE__, :test_key, []})
  end

  test "returns nothing if Guardian secret is a symmetric key", %{conn: conn} do
    assert conn
           |> get("/.well-known/jwks.json")
           |> json_response(200)
           |> Map.fetch!("keys")
           |> Enum.empty?()
  end

  defp test_with_key(conn, key, expected \\ nil) do
    current_config = Application.get_env(:cadet, Cadet.Auth.Guardian, [])
    expected = expected || @test_jwk |> Map.take(["alg", "e", "kty", "n", "use"])

    try do
      test_config = Keyword.put(current_config, :secret_key, key)
      Application.put_env(:cadet, Cadet.Auth.Guardian, test_config)

      assert conn |> get("/.well-known/jwks.json") |> json_response(200) == %{
               "keys" => [expected]
             }
    after
      Application.put_env(:cadet, Cadet.Auth.Guardian, current_config)
    end
  end

  def test_key do
    @test_jwk
  end
end
