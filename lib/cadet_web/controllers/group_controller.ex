defmodule CadetWeb.GroupController do
  use CadetWeb, :controller

  use PhoenixSwagger

  alias Cadet.Course.Groups

  def index(conn, _) do
    groups = Groups.get_group_overviews()

    render(conn, "index.json", groups: groups)
  end
end
