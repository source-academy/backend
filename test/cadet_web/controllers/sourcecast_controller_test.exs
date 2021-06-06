defmodule CadetWeb.SourcecastControllerTest do
  use CadetWeb.ConnCase

  alias CadetWeb.SourcecastController

  test "swagger" do
    SourcecastController.swagger_definitions()
    SourcecastController.swagger_path_index(nil)
    SourcecastController.swagger_path_create(nil)
    SourcecastController.swagger_path_delete(nil)
  end

  describe "GET /v2/sourcecast, unauthenticated" do
    test "renders a list of all sourcecast entries for public", %{
      conn: conn
    } do
      %{sourcecasts: sourcecasts} = seed_db()
      course = insert(:course)
      seed_db(course.id)

      expected =
        sourcecasts
        |> Enum.map(
          &%{
            "id" => &1.id,
            "title" => &1.title,
            "description" => &1.description,
            "uid" => &1.uid,
            "playbackData" => &1.playbackData,
            "uploader" => %{
              "name" => &1.uploader.name,
              "id" => &1.uploader.id
            },
            "url" => Cadet.Courses.SourcecastUpload.url({&1.audio, &1})
          }
        )

      res =
        conn
        |> get(build_url())
        |> json_response(200)
        |> Enum.map(&Map.delete(&1, "audio"))
        |> Enum.map(&Map.delete(&1, "inserted_at"))
        |> Enum.map(&Map.delete(&1, "updated_at"))

      assert expected == res
    end
  end

  describe "POST /course/{courseId}/sourcecast, unauthenticated" do
    test "unauthorized", %{conn: conn} do
      course = insert(:course)
      conn = post(conn, build_url(course.id), %{})
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  describe "DELETE /course/{courseId}/sourcecast, unauthenticated" do
    test "unauthorized", %{conn: conn} do
      course = insert(:course)
      seed_db(course.id)
      conn = delete(conn, build_url(course.id, 1), %{})
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  describe "GET /sourcecast, returns public sourcecasts (those without course_id)" do
    test "renders a list of all public sourcecast entries", %{
      conn: conn
    } do
      course = insert(:course)
      %{sourcecasts: sourcecasts} = seed_db()
      seed_db(course.id)

      expected =
        sourcecasts
        |> Enum.map(
          &%{
            "id" => &1.id,
            "title" => &1.title,
            "description" => &1.description,
            "uid" => &1.uid,
            "playbackData" => &1.playbackData,
            "uploader" => %{
              "name" => &1.uploader.name,
              "id" => &1.uploader.id
            },
            "url" => Cadet.Courses.SourcecastUpload.url({&1.audio, &1})
          }
        )

      res =
        conn
        |> get(build_url())
        |> json_response(200)
        |> Enum.map(&Map.delete(&1, "audio"))
        |> Enum.map(&Map.delete(&1, "inserted_at"))
        |> Enum.map(&Map.delete(&1, "updated_at"))

      assert expected == res
    end
  end

  describe "POST /course/{courseId}/sourcecast, student" do
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

      assert response(conn, 403) =~ "User is not permitted to upload"
    end
  end

  describe "DELETE /course/{courseId}/sourcecast, student" do
    @tag authenticate: :student
    test "prohibited", %{conn: conn} do
      course_id = conn.assigns[:course_id]

      conn = delete(conn, build_url(course_id, 1), %{})

      assert response(conn, 403) =~ "User is not permitted to delete"
    end
  end

  describe "POST /course/{courseId}/sourcecast, staff" do
    @tag authenticate: :staff
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

    @tag authenticate: :staff
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

    @tag authenticate: :staff
    test "missing parameter", %{conn: conn} do
      course_id = conn.assigns[:course_id]

      conn = post(conn, build_url(course_id), %{})
      assert response(conn, 400) =~ "Missing or invalid parameter(s)"
    end
  end

  describe "DELETE /course/{courseId}/sourcecast, staff" do
    @tag authenticate: :staff
    test "successful for public sourcecast", %{conn: conn} do
      course_id = conn.assigns[:course_id]

      %{sourcecasts: sourcecasts} = seed_db()
      sourcecast = List.first(sourcecasts)

      conn = delete(conn, build_url(course_id, sourcecast.id), %{})

      assert response(conn, 200) =~ "OK"
    end

    @tag authenticate: :staff
    test "successful for course sourcecast", %{conn: conn} do
      course_id = conn.assigns[:course_id]

      %{sourcecasts: sourcecasts} = seed_db(course_id)
      sourcecast = List.first(sourcecasts)

      conn = delete(conn, build_url(course_id, sourcecast.id), %{})

      assert response(conn, 200) =~ "OK"
    end
  end

  describe "POST /course/{courseId}/sourcecast, admin" do
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

  describe "DELETE /course/{courseId}/sourcecast, admin" do
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

  defp build_url(), do: "/v2/sourcecast/"
  defp build_url(course_id), do: "/v2/course/#{course_id}/sourcecast/"
  defp build_url(course_id, sourcecast_id), do: "#{build_url(course_id)}#{sourcecast_id}/"

  defp seed_db(course_id) do
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
          course_id: course_id
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
