defmodule CadetWeb.StoriesController do
  use CadetWeb, :controller
  use PhoenixSwagger

  alias Cadet.Repo
  alias Cadet.Stories.Story

  @doc """
  Fetches all stories
  """

  def index(conn, _) do
    stories =
    Story |> Repo.all()

    render(
      conn,
      "index.json",
      stories: stories
    )
  end



end
