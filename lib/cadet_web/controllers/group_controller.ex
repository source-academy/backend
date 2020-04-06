defmodule CadetWeb.GroupController do
  @moduledoc """
  Provides information about groups.
  """

  use CadetWeb, :controller
  use PhoenixSwagger

  import Cadet.Course.Groups

  def index(conn, _) do
    group_info = get_group_info()

    json(
      conn,
      group_info
    )
  end
end
