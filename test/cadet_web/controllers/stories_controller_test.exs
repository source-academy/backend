defmodule CadetWeb.StoriesControllerTest do
  use CadetWeb.ConnCase
  use Timex

  import Ecto.Query

  alias Cadet.Repo
  alias Cadet.Stories.Story
  alias CadetWeb.StoriesController

  setup do
    valid_params = %{
      open_at: Timex.shift(Timex.now(), days: 1),
      close_at: Timex.shift(Timex.now(), days: Enum.random(2..30)),
      is_published: false,
      filenames: ["mission-1.txt"],
      title: "Mission1",
      image_url: "http://example.com"
    }

    updated_params = %{
      title: "Mission2",
      image_url: "http://example.com/new"
    }

    {:ok, %{valid_params: valid_params, updated_params: updated_params}}
  end

  test "swagger" do
    StoriesController.swagger_definitions()
    StoriesController.swagger_path_index(nil)
    StoriesController.swagger_path_create(nil)
    StoriesController.swagger_path_delete(nil)
    StoriesController.swagger_path_update(nil)
  end

  describe "public access, unauthenticated" do
    test "GET /stories/", %{conn: conn} do
      conn = get(conn, build_url(), %{})
      assert response(conn, 401) =~ "Unauthorised"
    end

    test "POST /stories/new", %{conn: conn} do
      conn = post(conn, build_url("new"), %{})
      assert response(conn, 401) =~ "Unauthorised"
    end

    test "DELETE /stories/:storyid", %{conn: conn} do
      conn = delete(conn, build_url("storyid"), %{})
      assert response(conn, 401) =~ "Unauthorised"
    end

    test "POST /stories/:storyid", %{conn: conn} do
      conn = post(conn, build_url("storyid"), %{})
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  describe "GET /stories" do
    @tag authenticate: :student
    test "student permission, only obtain published open stories", %{
      conn: conn,
      valid_params: params
    } do
      one_week_ago = Timex.shift(Timex.now(), weeks: -1)

      insert(:story)
      insert(:story, %{params | :is_published => true})
      insert(:story, %{params | :open_at => one_week_ago})
      insert(:story, %{params | :is_published => true, :open_at => one_week_ago})

      {:ok, resp} =
        conn
        |> get(build_url())
        |> response(200)
        |> Jason.decode()

      assert Enum.count(resp) == 1
    end

    @tag authenticate: :staff
    test "obtain all stories", %{conn: conn, valid_params: params} do
      one_week_ago = Timex.shift(Timex.now(), weeks: -1)

      insert(:story)
      insert(:story, %{params | :is_published => true})
      insert(:story, %{params | :open_at => one_week_ago})
      insert(:story, %{params | :is_published => true, :open_at => one_week_ago})

      {:ok, resp} =
        conn
        |> get(build_url())
        |> response(200)
        |> Jason.decode()

      assert Enum.count(resp) == 4
    end

    @tag authenticate: :staff
    test "All fields are present and in the right format", %{conn: conn} do
      insert(:story)

      {:ok, [resp]} =
        conn
        |> get(build_url())
        |> response(200)
        |> Jason.decode()

      required_fields = ~w(openAt closeAt isPublished id title filenames imageUrl)

      Enum.each(required_fields, fn required_field ->
        value = resp[required_field]
        assert value != nil

        case required_field do
          "id" -> assert is_integer(value)
          "filenames" -> assert is_list(value)
          "isPublished" -> assert is_boolean(value)
          _ -> assert is_binary(value)
        end
      end)
    end
  end

  describe "DELETE /stories/:storyid" do
    @tag authenticate: :student
    test "student permission, forbidden", %{conn: conn} do
      conn = delete(conn, build_url(1), %{})
      assert response(conn, 403) =~ "User not allowed to manage stories"
    end

    @tag authenticate: :staff
    test "deletes story", %{conn: conn} do
      to_be_deleted = insert(:story)
      resp = delete(conn, build_url(to_be_deleted.id), %{})
      assert response(resp, 204) == ""
    end
  end

  describe "POST /stories/new" do
    @tag authenticate: :student
    test "student permission, forbidden", %{conn: conn, valid_params: params} do
      conn = post(conn, build_url("new"), params)
      assert response(conn, 403) =~ "User not allowed to manage stories"
    end

    @tag authenticate: :staff
    test "creates a new story", %{conn: conn, valid_params: params} do
      conn = post(conn, build_url("new"), params)

      assert Story
             |> where(title: ^params.title)
             |> Repo.one() != nil

      assert response(conn, 200) == ""
    end
  end

  describe "POST /stories/:storyid" do
    @tag authenticate: :student
    test "student permission, forbidden", %{conn: conn, valid_params: params} do
      conn = post(conn, build_url(1), %{"story" => params})
      assert response(conn, 403) =~ "User not allowed to manage stories"
    end

    @tag authenticate: :staff
    test "updates a story", %{conn: conn, updated_params: updated_params} do
      story = insert(:story)
      conn = post(conn, build_url(story.id), %{"story" => updated_params})

      assert Story
             |> where(title: ^updated_params.title)
             |> Repo.one() != nil

      assert response(conn, 200) == ""
    end
  end

  defp build_url, do: "/v1/stories/"
  defp build_url(url), do: "#{build_url()}/#{url}"
end
