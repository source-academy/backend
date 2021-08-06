defmodule CadetWeb.StoriesControllerTest do
  use CadetWeb.ConnCase
  use Timex

  import Ecto.Query

  alias Cadet.Courses.Course
  alias Cadet.Repo
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
  end

  describe "unauthenticated" do
    test "GET /v2/courses/{course_id}/stories/", %{conn: conn} do
      course = insert(:course)
      conn = get(conn, build_url(course.id), %{})
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  describe "GET /v2/courses/{course_id}/stories" do
    @tag authenticate: :student
    test "student permission, only obtain published open stories from own course", %{
      conn: conn,
      valid_params: params
    } do
      course_id = conn.assigns[:course_id]
      course = Course |> where(id: ^course_id) |> Repo.one()
      one_week_ago = Timex.shift(Timex.now(), weeks: -1)

      insert(:story, %{course: course})
      insert(:story, %{Map.put(params, :course, course) | :is_published => true})
      insert(:story, %{Map.put(params, :course, course) | :open_at => one_week_ago})

      insert(:story, %{
        Map.put(params, :course, course)
        | :is_published => true,
          :open_at => one_week_ago
      })

      insert(:story, %{
        Map.put(params, :course, build(:course))
        | :is_published => true,
          :open_at => one_week_ago
      })

      {:ok, resp} =
        conn
        |> get(build_url(course_id))
        |> response(200)
        |> Jason.decode()

      assert Enum.count(resp) == 1
    end

    @tag authenticate: :staff
    test "obtain all stories from own course", %{conn: conn, valid_params: params} do
      course_id = conn.assigns[:course_id]
      course = Course |> where(id: ^course_id) |> Repo.one()
      one_week_ago = Timex.shift(Timex.now(), weeks: -1)

      insert(:story, %{course: course})
      insert(:story, %{Map.put(params, :course, course) | :is_published => true})
      insert(:story, %{Map.put(params, :course, course) | :open_at => one_week_ago})

      insert(:story, %{
        Map.put(params, :course, course)
        | :is_published => true,
          :open_at => one_week_ago
      })

      insert(:story, %{course: build(:course)})

      {:ok, resp} =
        conn
        |> get(build_url(course_id))
        |> response(200)
        |> Jason.decode()

      assert Enum.count(resp) == 4
    end

    @tag authenticate: :staff
    test "All fields are present and in the right format", %{conn: conn} do
      course_id = conn.assigns[:course_id]
      course = Course |> where(id: ^course_id) |> Repo.one()

      insert(:story, %{course: course})

      {:ok, [resp]} =
        conn
        |> get(build_url(course_id))
        |> response(200)
        |> Jason.decode()

      required_fields = ~w(openAt closeAt isPublished id title filenames imageUrl courseId)

      Enum.each(required_fields, fn required_field ->
        value = resp[required_field]
        assert value != nil

        case required_field do
          "id" -> assert is_integer(value)
          "filenames" -> assert is_list(value)
          "isPublished" -> assert is_boolean(value)
          "courseId" -> assert is_integer(value)
          _ -> assert is_binary(value)
        end
      end)
    end
  end

  defp build_url(course_id), do: "/v2/courses/#{course_id}/stories"
end
