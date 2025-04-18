defmodule CadetWeb.AdminSourcecastControllerTest do
  use CadetWeb.ConnCase

  import Ecto.Query

  alias Cadet.Repo
  alias Cadet.Courses.Course
  alias CadetWeb.AdminSourcecastController

  test "swagger" do
    AdminSourcecastController.swagger_definitions()
    AdminSourcecastController.swagger_path_create(nil)
    AdminSourcecastController.swagger_path_delete(nil)
  end

  describe "POST /v2/courses/{course_id}/sourcecast, unauthenticated" do
    test "unauthorized", %{conn: conn} do
      course = insert(:course)
      conn = post(conn, build_url(course.id), %{})
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  describe "DELETE /v2/courses/{course_id}/sourcecast, unauthenticated" do
    test "unauthorized", %{conn: conn} do
      course = insert(:course)
      seed_db(course.id)
      conn = delete(conn, build_url(course.id, 1), %{})
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  describe "POST /v2/courses/{course_id}/sourcecast, student" do
    @tag authenticate: :student
    test "prohibited", %{conn: conn} do
      course_id = conn.assigns[:course_id]

      conn =
        post(conn, build_url(course_id), %{
          "sourcecast" => %{
            "title" => "Title",
            "description" => "Description",
            "playbackData" =>
              "{\"init\":{\"editorValue\":\"// Type your program in here!\"},\"inputs\":[]}",
            "audio" => %Plug.Upload{
              content_type: "audio/wav",
              filename: "upload.wav",
              path: "test/fixtures/upload.wav"
            }
          }
        })

      assert response(conn, 403) =~ "Forbidden"
    end
  end

  describe "DELETE /v2/courses/{course_id}/sourcecast, student" do
    @tag authenticate: :student
    test "prohibited", %{conn: conn} do
      course_id = conn.assigns[:course_id]

      conn = delete(conn, build_url(course_id, 1), %{})

      assert response(conn, 403) =~ "Forbidden"
    end
  end

  describe "POST /v2/courses/{course_id}/sourcecast, staff" do
    # @tag authenticate: :staff
    # test "successful for public sourcecast", %{conn: conn} do
    #   course_id = conn.assigns[:course_id]

    #   post_conn =
    #     post(conn, build_url(course_id), %{
    #       "sourcecast" => %{
    #         "title" => "Title",
    #         "description" => "Description",
    #         "playbackData" =>
    #           "{\"init\":{\"editorValue\":\"// Type your program in here!\"},\"inputs\":[]}",
    #         "audio" => %Plug.Upload{
    #           content_type: "audio/wav",
    #           filename: "upload.wav",
    #           path: "test/fixtures/upload.wav"
    #         }
    #       },
    #       "public" => true
    #     })

    #   assert response(post_conn, 200) == "OK"

    #   expected = [
    #     %{
    #       "title" => "Title",
    #       "description" => "Description",
    #       "playbackData" =>
    #         "{\"init\":{\"editorValue\":\"// Type your program in here!\"},\"inputs\":[]}",
    #       "uploader" => %{
    #         "id" => conn.assigns[:current_user].id,
    #         "name" => conn.assigns[:current_user].name
    #       },
    #       "courseId" => nil
    #     }
    #   ]

    #   res =
    #     conn
    #     |> get(build_url())
    #     |> json_response(200)
    #     |> Enum.map(&Map.delete(&1, "audio"))
    #     |> Enum.map(&Map.delete(&1, "inserted_at"))
    #     |> Enum.map(&Map.delete(&1, "updated_at"))
    #     |> Enum.map(&Map.delete(&1, "id"))
    #     |> Enum.map(&Map.delete(&1, "uid"))
    #     |> Enum.map(&Map.delete(&1, "url"))

    #   assert expected == res
    # end

    @tag authenticate: :staff
    test "successful for course sourcecast", %{conn: conn} do
      course_id = conn.assigns[:course_id]

      post_conn =
        post(conn, build_url(course_id), %{
          "sourcecast" => %{
            "title" => "Title",
            "description" => "Description",
            "playbackData" =>
              "{\"init\":{\"editorValue\":\"// Type your program in here!\"},\"inputs\":[]}",
            "audio" => %Plug.Upload{
              content_type: "audio/wav",
              filename: "upload.wav",
              path: "test/fixtures/upload.wav"
            }
          }
        })

      assert response(post_conn, 200) == "OK"

      expected = [
        %{
          "title" => "Title",
          "description" => "Description",
          "playbackData" =>
            "{\"init\":{\"editorValue\":\"// Type your program in here!\"},\"inputs\":[]}",
          "uploader" => %{
            "id" => conn.assigns[:current_user].id,
            "name" => conn.assigns[:current_user].name
          },
          "courseId" => course_id
        }
      ]

      res =
        conn
        |> get("/v2/courses/#{course_id}/sourcecast")
        |> json_response(200)
        |> Enum.map(&Map.delete(&1, "audio"))
        |> Enum.map(&Map.delete(&1, "inserted_at"))
        |> Enum.map(&Map.delete(&1, "updated_at"))
        |> Enum.map(&Map.delete(&1, "id"))
        |> Enum.map(&Map.delete(&1, "uid"))
        |> Enum.map(&Map.delete(&1, "url"))

      assert expected == res
    end

    @tag authenticate: :staff
    test "missing parameter", %{conn: conn} do
      course_id = conn.assigns[:course_id]

      conn = post(conn, build_url(course_id), %{})
      assert response(conn, 400) =~ "Missing or invalid parameter(s)"
    end

    @tag authenticate: :staff
    test "invalid changeset", %{conn: conn} do
      course_id = conn.assigns[:course_id]

      conn = post(conn, build_url(course_id), %{"sourcecast" => %{}})

      assert response(conn, 400) =~
               "title can't be blank\naudio can't be blank\nplaybackData can't be blank"
    end
  end

  describe "DELETE /v2/courses/{course_id}/sourcecast, staff" do
    # @tag authenticate: :staff
    # test "successful for public sourcecast", %{conn: conn} do
    #   course_id = conn.assigns[:course_id]

    #   %{sourcecasts: sourcecasts} = seed_db()
    #   sourcecast = List.first(sourcecasts)

    #   conn = delete(conn, build_url(course_id, sourcecast.id), %{})

    #   assert response(conn, 200) =~ "OK"
    # end

    @tag authenticate: :staff
    test "successful for course sourcecast", %{conn: conn} do
      course_id = conn.assigns[:course_id]

      %{sourcecasts: sourcecasts} = seed_db(course_id)
      sourcecast = List.first(sourcecasts)

      conn = delete(conn, build_url(course_id, sourcecast.id))

      assert response(conn, 200) =~ "OK"
    end

    @tag authenticate: :staff
    test "fail due to not found", %{conn: conn} do
      course_id = conn.assigns[:course_id]

      conn = delete(conn, build_url(course_id, 1))

      assert response(conn, 404) =~ "Sourcecast not found"
    end
  end

  describe "POST /v2/courses/{course_id}/sourcecast, admin" do
    @tag authenticate: :admin
    test "successful for public sourcecast", %{conn: conn} do
      course_id = conn.assigns[:course_id]

      conn =
        post(conn, build_url(course_id), %{
          "sourcecast" => %{
            "title" => "Title",
            "description" => "Description",
            "playbackData" =>
              "{\"init\":{\"editorValue\":\"// Type your program in here!\"},\"inputs\":[]}",
            "audio" => %Plug.Upload{
              content_type: "audio/wav",
              filename: "upload.wav",
              path: "test/fixtures/upload.wav"
            }
          },
          "public" => true
        })

      assert response(conn, 200) == "OK"
    end

    @tag authenticate: :admin
    test "successful for course sourcecast", %{conn: conn} do
      course_id = conn.assigns[:course_id]

      conn =
        post(conn, build_url(course_id), %{
          "sourcecast" => %{
            "title" => "Title",
            "description" => "Description",
            "playbackData" =>
              "{\"init\":{\"editorValue\":\"// Type your program in here!\"},\"inputs\":[]}",
            "audio" => %Plug.Upload{
              content_type: "audio/wav",
              filename: "upload.wav",
              path: "test/fixtures/upload.wav"
            }
          }
        })

      assert response(conn, 200) == "OK"
    end

    @tag authenticate: :admin
    test "missing parameter", %{conn: conn} do
      course_id = conn.assigns[:course_id]

      conn = post(conn, build_url(course_id), %{})
      assert response(conn, 400) =~ "Missing or invalid parameter(s)"
    end
  end

  describe "DELETE /v2/courses/{course_id}/sourcecast, admin" do
    @tag authenticate: :admin
    test "successful for public sourcecast", %{conn: conn} do
      course_id = conn.assigns[:course_id]

      %{sourcecasts: sourcecasts} = seed_db()
      sourcecast = List.first(sourcecasts)

      conn = delete(conn, build_url(course_id, sourcecast.id), %{})

      assert response(conn, 200) =~ "OK"
    end

    @tag authenticate: :admin
    test "successful for course sourcecast", %{conn: conn} do
      course_id = conn.assigns[:course_id]

      %{sourcecasts: sourcecasts} = seed_db(course_id)
      sourcecast = List.first(sourcecasts)

      conn = delete(conn, build_url(course_id, sourcecast.id), %{})

      assert response(conn, 200) =~ "OK"
    end
  end

  defp build_url(course_id), do: "/v2/courses/#{course_id}/admin/sourcecast/"
  defp build_url(course_id, sourcecast_id), do: "#{build_url(course_id)}#{sourcecast_id}/"

  defp seed_db(course_id) do
    course = Course |> where(id: ^course_id) |> Repo.one()

    sourcecasts =
      for i <- 0..4 do
        insert(:sourcecast, %{
          title: "Title#{i}",
          description: "Description#{i}",
          uid: "unique_id#{i}",
          playbackData:
            "{\"init\":{\"editorValue\":\"// Type your program in here!\"},\"inputs\":[]}",
          audio: %Plug.Upload{
            content_type: "audio/wav",
            filename: "upload#{i}.wav",
            path: "test/fixtures/upload.wav"
          },
          course: course
        })
      end

    %{sourcecasts: sourcecasts}
  end

  defp seed_db do
    sourcecasts =
      for i <- 5..9 do
        insert(:sourcecast, %{
          title: "Title#{i}",
          description: "Description#{i}",
          uid: "unique_id#{i}",
          playbackData:
            "{\"init\":{\"editorValue\":\"// Type your program in here!\"},\"inputs\":[]}",
          audio: %Plug.Upload{
            content_type: "audio/wav",
            filename: "upload#{i}.wav",
            path: "test/fixtures/upload.wav"
          }
        })
      end

    %{sourcecasts: sourcecasts}
  end
end
