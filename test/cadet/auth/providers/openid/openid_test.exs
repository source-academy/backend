defmodule Cadet.Auth.Providers.OpenIDTest do
  @moduledoc """
  Tests the OpenID authentication provider by simulating an OpenID
  authentication server.

  The RSA keypair used to generate the token below is as follows (as a JWK):

  ```
  {
    "p": "3jfRwYW0kdmSyxjalJY03koNmaoeTqDE1_UQoT3T-BvzipuZoTns44WfTZGvKpsRH8GjTxgiP4JDDl27JYfGvrFz9e-HTmJJfalycraYddmRYCRJbwfyLHj5agul0wktIpG3C20VTGo3oXWvCpo2EaCfK-8neYsm_VLyH9Am4aE",
    "kty": "RSA",
    "q": "uUk4gQLHjq13AbPD55dc8oDSwvvqCzOsfQOu_cFjFJ50epxYKjO-A2Qjz_gzCvXEfRuPg8kGBAduHgkM31H_4Gu2i-Qf6xRX2A6GNW5fNteDY-v2fBV6JFSrq3BXu2XYgoacK-1bGOjEy30Gix1hqcItF6BbA04lhiKnOvmG_T0",
    "d": "EQd0vYE8-ky7oT6LAyYBZPI7wCFEcBYUbY-3ddn_R0_b3wNMmg97zQurtOVaOZfvkTn0byRlHm-dvI1T-c2EIjaUjGBszTs6xuMjbVKzuc0i5_f_U5sU37MAei2TCKQsviZqmuu0V8njVLDiVEZyenH4DoliHCHzPHm8sUyv0QlaFA5dDWYusdKCXwRKNi00Sqn-IbbRBE48JbiqRkzdj-oK672zUT-PY27j6v7-uVzZTC_bxBisvyqzWSDQi_BNXoTALfkE0jw_WUnCJOj99YR87IvjrxJJHVljAXcbKR1EWFO6Xtg1f4YKJir-k-C2hooWWuCnkyx-jPL4a2-ogQ",
    "e": "AQAB",
    "use": "sig",
    "qi": "0PHNIY9f0zNaYDr7Yygp_w7nvuJPoH8dthVehYgBGRaL87VtRzXF4IdNWmQdPDDKUWJ0tPmgOhb7ilT9IjLAHkbUtNtxrjPtWQZ68Lr1WCcR99uT9AxQZN5NrxnjOqPTeiRuiPB11FHUcwfvQMywG8TN2LKrjFt_a96iQ7jCHYY",
    "dp": "DE_NaEpvIbGLR4NeAON9lF9H956MRVD09v4V6MkTKGjsCl7qmRsre8OYeuS6bsLepQLGeIhexWQDMRWSW9b09PXB9ftKZNZfOf4cYCyrr8PZIRmBlAw9p6cgMnbovhOBE6w9Fv35Mx2jbWemxhCbNEjQ6M88QairBVgGICsZLGE",
    "alg": "RS256",
    "dq": "RDhjZ4zgcPYJdUT9Ao5GmLs53rTmLY2vGrB6g8_qbTMSa_qYs6Etew4p6W7XTFfFKtM0-i7P2jfqIYDvjmIgtj6yjbtGzUVGOrTOUWn8ALNFG0tMC8_Ukv_h3VOV2dfb6eMqKTpRalB59PppqFr_FIP8GlDecc8aHdMwg5RQUXk",
    "n": "oNXli9w7TojL3pTV5M-BfgykoS-Tb-pTcEU_srnogrd5qwq4vHPDz23uiJ3eiT9jUl1Atrlu97no6Ua-QvqTC5LmGX31gn3OIAUaUlmKekuCT0eCZt9eEaFW2kKsXyeQOfbzw5SwLpFAeSoPBXOv5sggMHTmkBshQZg59ctujtMvS-45q4q0Bow5Pzue1nGgFsaQ87C4ZBN-N2LC7ercWnhbnSC5fx0JCfFt0Dw3t_-7YDYIHUWpZLR51Vr9BTF5jOHalLihXP3-mOlTR0htqReDIhlWQCNim-6DkT6yCyG8w-qv-jTv4lW7NKRrlKpzmgMoHGd2PRjHiw2UuYXgXQ",
    "kid": "1"
  }
  ```
  """

  use ExUnit.Case, async: false

  alias Cadet.Auth.Providers.OpenID
  alias Plug.Conn, as: PlugConn

  @jwks_json """
  {"keys":[{"kty":"RSA","e":"AQAB","use":"sig","alg":"RS256","n":"oNXli9w7TojL3pTV5M-BfgykoS-Tb-pTcEU_srnogrd5qwq4vHPDz23uiJ3eiT9jUl1Atrlu97no6Ua-QvqTC5LmGX31gn3OIAUaUlmKekuCT0eCZt9eEaFW2kKsXyeQOfbzw5SwLpFAeSoPBXOv5sggMHTmkBshQZg59ctujtMvS-45q4q0Bow5Pzue1nGgFsaQ87C4ZBN-N2LC7ercWnhbnSC5fx0JCfFt0Dw3t_-7YDYIHUWpZLR51Vr9BTF5jOHalLihXP3-mOlTR0htqReDIhlWQCNim-6DkT6yCyG8w-qv-jTv4lW7NKRrlKpzmgMoHGd2PRjHiw2UuYXgXQ","kid":"1"}]}
  """

  @username "username"

  @openid_provider_name :test

  setup_all do
    Application.ensure_all_started(:bypass)
    bypass = Bypass.open()

    Bypass.stub(bypass, "GET", "/.well-known/jwks.json", fn conn ->
      conn
      |> PlugConn.put_resp_header("content-type", "application/json")
      |> PlugConn.resp(200, @jwks_json)
    end)

    Bypass.stub(bypass, "GET", "/.well-known/openid-configuration", fn conn ->
      conn
      |> PlugConn.put_resp_header("content-type", "application/json")
      |> PlugConn.resp(200, """
      {
        "id_token_signing_alg_values_supported": ["RS256"],
        "issuer": "issuer",
        "jwks_uri": "#{endpoint_url(bypass.port, ".well-known/jwks.json")}",
        "response_types_supported": ["code","token"],
        "scopes_supported": ["openid","email","phone","profile"],
        "subject_types_supported": ["public"],
        "token_endpoint": "#{endpoint_url(bypass.port, "oauth2/token")}",
        "token_endpoint_auth_methods_supported": ["client_secret_basic","client_secret_post"]
      }
      """)
    end)

    openid_worker =
      OpenIDConnect.Worker.start_link([
        {@openid_provider_name,
         [
           discovery_document_uri: endpoint_url(bypass.port, ".well-known/openid-configuration"),
           client_id: "dummy",
           client_secret: "dummydummy",
           response_type: "code",
           scope: "openid profile"
         ]}
      ])

    {:ok, bypass: bypass, openid_worker: openid_worker}
  end

  defp endpoint_url(port, path),
    do: "http://localhost:#{port}" |> URI.merge(path) |> URI.to_string()

  defp bypass_return_token(bypass, token) do
    Bypass.stub(bypass, "POST", "/oauth2/token", fn conn ->
      conn
      |> PlugConn.put_resp_header("content-type", "application/json")
      |> PlugConn.resp(200, ~s({"access_token":"#{token}"}))
    end)
  end

  @config %{
    openid_provider: @openid_provider_name,
    claim_extractor: Cadet.Auth.Providers.CognitoClaimExtractor
  }

  @okay_token "eyJraWQiOiIxIiwiYWxnIjoiUlMyNTYifQ.eyJjb2duaXRvOmdyb3VwcyI6WyJhZG1pbiJdLCJ1c2VybmFtZSI6InVzZXJuYW1lIn0.Nrh7bY9Lj6OwmJfAiO6UUqEiK4fbvlJaRC-OzlSDy8f0rTUMlM6U2FIVFYGCI1OK_aKUDY_u3t0MElyl-f-6Kw3W_6odhrHpx5KnKmqs9FfwbD_AzEZI93GguV8y90OhMoP0O5ig-b63CDKu-VZqxpGn_MC1GbxMMgY_4V90o4nm502rgKuZATGwsxhCe-42w87dv7ufHjN2HclMu-A8jrP0WzYGDDvjhKJKTwFdpVglEGQGWYqemqZyr9_VarnOiIPO47i46rOZfc2DgOBI0LyMQvLWYVuPep1up0ja5FWUzu4NkG_sYSRjhQ1hcTj-kfR-cy134YymxhfaUOZk8w"

  test "successfully", %{bypass: bypass} do
    # the dummy server just returns what we send as the code as the token, so we
    # can test various tokens

    bypass_return_token(bypass, @okay_token)

    assert {:ok, %{token: @okay_token, username: @username}} =
             OpenID.authorise(@config, %{code: "dummy_code", redirect_uri: ""})

    assert {:ok, @username} == OpenID.get_name(@config, @okay_token)
  end

  @no_username_token "eyJraWQiOiIxIiwiYWxnIjoiUlMyNTYifQ.eyJjb2duaXRvOmdyb3VwcyI6WyJhZG1pbiJdfQ.oAcQXHRZjm9lje8SoIkLBan4ucZDorWuqVU4dtFySh0br48f722VOZ4Ejwm23ha8TMYSmHpOnyS0WKOrBN1tYtmTvaApLT1Q7zphtGLoGVhrQRx-cM23vCswLQWesbmhgD-QzFkTXCnAXy8N2EjaBehWJbBuslZZpqH1R9LIZiqzTEtoY1wIK_ndClZZ2qswVuNdoWBWJShJDvmJAgphb7roKEG5KEc70jb8cOE79CKXpj_uKJwLYrcLpzVyZwLNJevi6FiT2wLIBr2HCL8_Vrv6SmVtLlvRU23-IIyXxdAce4KIyMTC2BovvTgGZtiXPjMOlcklyZMDeIyaWBosMA"

  test "authorise with no username in token", %{bypass: bypass} do
    bypass_return_token(bypass, @no_username_token)

    assert {:error, :invalid_credentials, "No username specified in token"} ==
             OpenID.authorise(@config, %{code: "dummy_code", redirect_uri: ""})
  end

  test "get_name with no name in token" do
    assert {:error, :invalid_credentials, "No name specified in token"} ==
             OpenID.get_name(@config, @no_username_token)
  end

  @expired_token "eyJraWQiOiIxIiwiYWxnIjoiUlMyNTYifQ.eyJjb2duaXRvOmdyb3VwcyI6WyJhZG1pbiJdLCJ1c2VybmFtZSI6InVzZXJuYW1lIiwiZXhwIjowfQ.M6VMo5_xtFAl75kwpLWsDRArYJLpqIp3qkks3TvExQXqOZ9eI98bm_R1VFMkbJ0-URQqURiBO6SYA1uNdXoEMoDtv0tV-P26fEy5pcdGC-sYXkbgXsw4iKAuSUfc4GSwDLEcYb9n6gQAG6pqbHAvft_L3f6RLLhP6GWWnOZ3upRDwsYcZSyYvDdpuVpCtHOfsMPANeXmZPHbYoRWQULU2okklPmXrc4sO0HO_zVocMus9DDf9hF0NmGl0diUQBA-w3i9hkcqsuhmxhOLApPre49TK37HDd0ileo9GIMGMPuOfXd44d8fHg5yr5MVqJLeH2RoHh9ZD_myPnTBG0GptA"

  test "expired token", %{bypass: bypass} do
    bypass_return_token(bypass, @expired_token)

    assert {:error, :invalid_credentials, "Failed to verify token claims (token expired?)"} ==
             OpenID.authorise(@config, %{code: "dummy_code", redirect_uri: ""})
  end

  @invalid_signature_token "eyJraWQiOiIxIiwiYWxnIjoiUlMyNTYifQ.eyJjb2duaXRvOmdyb3VwcyI6WyJhZG1pbiJdLCJ1c2VybmFtZSI6InVzZXJuYW1lIiwiZXhwIjowfQ.M6VMo5_xtFAl75kwpLWsDRArYJLpqIp3qkks3TvExQXqOZ9eI98bm_R1VFMkbJ0-URQqURiBO6SYA1uNdXoEMoDtv0tV-P26fEy5pcdGC-sYXkbgXsw4iKAuSUfc4GSwDLEcYb9n6gQAG6pqbHAvft_L3f6RLLhP6GWWnOZ3upRDwsYcZSyYvDdpuVpCtHOfsMPANeXmZPHbYoRWQULU2okklPmXrc4sO0HO_zVocMus9DDf9hF0NmGl0diUQBA-w3i9hkcqsuhmxhOLApPre49TK37HDd1ileo9GIMGMPuOfXd44d8fHg5yr5MVqJLeH2RoHh9ZD_myPnTBG0GptA"

  test "invalid token signature", %{bypass: bypass} do
    bypass_return_token(bypass, @invalid_signature_token)

    assert {:error, :invalid_credentials, "Failed to verify token"} ==
             OpenID.authorise(@config, %{code: "dummy_code", redirect_uri: ""})
  end

  test "non-successful HTTP status", %{bypass: bypass} do
    Bypass.stub(bypass, "POST", "/oauth2/token", fn conn ->
      PlugConn.resp(conn, 403, "")
    end)

    assert {:error, :invalid_credentials, "Failed to fetch token from OpenID provider"} ==
             OpenID.authorise(@config, %{code: "dummy_code", redirect_uri: ""})
  end

  test "missing token", %{bypass: bypass} do
    Bypass.stub(bypass, "POST", "/oauth2/token", fn conn ->
      conn
      |> PlugConn.put_resp_header("content-type", "application/json")
      |> PlugConn.resp(200, ~s({}))
    end)

    assert {:error, :invalid_credentials, "Missing token in response from OpenID provider"} ==
             OpenID.authorise(@config, %{code: "dummy_code", redirect_uri: ""})
  end
end
