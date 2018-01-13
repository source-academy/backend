defmodule CadetWeb.SessionControllerTest do
  use CadetWeb.ConnCase

  import Cadet.Factory

  test "GET /session/new", %{conn: conn} do
    conn = get(conn, "/session/new")
    assert html_response(conn, 200)
  end

  describe "POST /session" do
    test "invalid input", %{conn: conn} do
      conn =
        post(conn, "/session", %{
          "login" => %{
            "email" => "",
            "password" => "somepassword"
          }
        })

      assert html_response(conn, 200) =~ "email can&#39;t be blank"
    end

    test "valid input and valid user", %{conn: conn} do
      test_password = "somepassword"
      user = insert(:user)

      email =
        insert(:email, %{
          token: Pbkdf2.hash_pwd_salt(test_password),
          user: user
        })

      conn =
        post(conn, "/session", %{
          "login" => %{
            "email" => email.uid,
            "password" => test_password
          }
        })

      assert redirected_to(conn) =~ "/"
    end
  end

  test "DELETE /session/:id", %{conn: conn} do
    conn = delete(conn, "/session/3")
    assert html_response(conn, 302)
  end
end
