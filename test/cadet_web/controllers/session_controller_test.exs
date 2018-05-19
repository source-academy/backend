# defmodule CadetWeb.SessionControllerTest do
#   use CadetWeb.ConnCase
# 
#   import Cadet.Factory
# 
#   alias CadetWeb.SessionController
# 
#   test "swagger" do
#     # Cos swagger
#     SessionController.swagger_definitions()
#     # Found out the real name after macro from source code
#     SessionController.swagger_path_create(nil)
#   end
# 
#   # test "GET /session/new", %{conn: conn} do
#   #   conn = get(conn, "/session/new")
#   #   assert html_response(conn, 200)
#   # end
# 
#   # describe "POST /session" do
#   #   test "blank email", %{conn: conn} do
#   #     conn =
#   #       post(conn, "/session", %{
#   #         "login" => %{
#   #           "email" => "",
#   #           "password" => "somepassword"
#   #         }
#   #       })
# 
#   #     assert html_response(conn, 200) =~ "Email can&#39;t be blank"
#   #   end
# 
#   #   test "blank password", %{conn: conn} do
#   #     conn =
#   #       post(conn, "/session", %{
#   #         "login" => %{
#   #           "email" => "test@gmail.com",
#   #           "password" => ""
#   #         }
#   #       })
# 
#   #     assert html_response(conn, 200) =~ "Password can&#39;t be blank"
#   #   end
# 
#   #   test "email not found", %{conn: conn} do
#   #     conn =
#   #       post(conn, "/session", %{
#   #         "login" => %{
#   #           "email" => "unknown@gmail.com",
#   #           "password" => "somepassword"
#   #         }
#   #       })
# 
#   #     assert get_flash(conn, :error) == "E-mail not registered in the system"
#   #     assert redirected_to(conn) =~ "/session/new"
#   #   end
# 
#   #   test "password invalid", %{conn: conn} do
#   #     test_password = "somepassword"
#   #     user = insert(:user)
# 
#   #     email =
#   #       insert(:email, %{
#   #         token: Pbkdf2.hash_pwd_salt(test_password),
#   #         user: user
#   #       })
# 
#   #     conn =
#   #       post(conn, "/session", %{
#   #         "login" => %{
#   #           "email" => email.uid,
#   #           "password" => "somepassword2"
#   #         }
#   #       })
# 
#   #     assert get_flash(conn, :error) == "Invalid e-mail or password"
#   #     assert redirected_to(conn) =~ "/session/new"
#   #   end
# 
#   #   test "valid input and valid user", %{conn: conn} do
#   #     test_password = "somepassword"
#   #     user = insert(:user)
# 
#   #     email =
#   #       insert(:email, %{
#   #         token: Pbkdf2.hash_pwd_salt(test_password),
#   #         user: user
#   #       })
# 
#   #     conn =
#   #       post(conn, "/session", %{
#   #         "login" => %{
#   #           "email" => email.uid,
#   #           "password" => test_password
#   #         }
#   #       })
# 
#   #     assert redirected_to(conn) =~ "/"
#   #   end
#   # end
# 
#   @tag authenticate: :student
#   test "GET /session/logout", %{conn: conn} do
#     conn = get(conn, "/session/logout")
#     assert redirected_to(conn) =~ "/session/new"
#     conn = get(conn, "/")
#     assert html_response(conn, 401) =~ "/session/new"
#   end
# end
