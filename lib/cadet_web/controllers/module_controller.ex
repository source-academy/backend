defmodule CadetWeb.ModuleController do
    @moduledoc """
    Synchronize local module files witn GitHub repository via WebHook
    and repond HTTP resquest from frontend
    """
  
    use CadetWeb, :controller
  
    use PhoenixSwagger
  
    def handle(conn, _payload) do
      repo = Git.new("priv/module_static")
      IO.puts(Git.status!(repo))
      Git.pull(repo, ~w(origin master))
      IO.puts(Git.log!(repo)) 
      text(conn, "OK")
    end
  
    def not_found(conn, _) do
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(404, "Module not found")
    end
  
    swagger_path :handle do
      post("/webhook")
      summary("Handle payloads from GitHub and synchronize local files.")
      security([%{JWT: []}])
  
      consumes("application/json")
      
      parameters do
        payload(:path, :string, "HTTP POST payload from GitHub", required: true)
      end
      
      response(200, "OK")
    end
  
    swagger_path :not_found do
      get("/static")
      summary("Response that the requested URL is not found.")
      security([%{JWT: []}])
  
      response(404, "Module not found")
    end
  end