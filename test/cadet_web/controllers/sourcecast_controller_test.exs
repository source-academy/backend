defmodule CadetWeb.SourcecastControllerTest do
  use CadetWeb.ConnCase

  alias CadetWeb.SourcecastController

  test "swagger" do
    SourcecastController.swagger_definitions()
    SourcecastController.swagger_path_index(nil)
    SourcecastController.swagger_path_create(nil)
    SourcecastController.swagger_path_delete(nil)
  end

  describe "GET /sourcecast, unauthenticated" do
    test "renders a list of all sourcecast entries for public", %{
      conn: conn
    } do
      %{sourcecasts: sourcecasts} = seed_db()

      expected =
        sourcecasts
        |> Enum.map(
          &%{
            "id" => &1.id,
            "title" => &1.title,
            "description" => &1.description,
            "playbackData" => &1.playbackData,
            "uploader" => %{
              "name" => &1.uploader.name,
              "id" => &1.uploader.id
            },
            "url" => Cadet.Course.Upload.url({&1.audio, &1})
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

  describe "POST /sourcecast, unauthenticated" do
    test "unauthorized", %{conn: conn} do
      conn = post(conn, build_url(), %{})
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  describe "DELETE /sourcecast, unauthenticated" do
    test "unauthorized", %{conn: conn} do
      conn = delete(conn, build_url(1), %{})
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  describe "GET /sourcecast, all roles" do
    test "renders a list of all sourcecast entries", %{
      conn: conn
    } do
      %{sourcecasts: sourcecasts} = seed_db()

      expected =
        sourcecasts
        |> Enum.map(
          &%{
            "id" => &1.id,
            "title" => &1.title,
            "description" => &1.description,
            "playbackData" => &1.playbackData,
            "uploader" => %{
              "name" => &1.uploader.name,
              "id" => &1.uploader.id
            },
            "url" => Cadet.Course.Upload.url({&1.audio, &1})
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

  describe "POST /sourcecast, student" do
    @tag authenticate: :student
    test "prohibited", %{conn: conn} do
      conn =
        post(conn, build_url(), %{
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

  describe "DELETE /sourcecast, student" do
    @tag authenticate: :student
    test "prohibited", %{conn: conn} do
      conn = delete(conn, build_url(1), %{})

      assert response(conn, 403) =~ "User is not permitted to delete"
    end
  end

  describe "POST /sourcecast, staff" do
    @tag authenticate: :staff
    test "successful", %{conn: conn} do
      conn =
        post(conn, build_url(), %{
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
      conn = post(conn, build_url(), %{})
      assert response(conn, 400) =~ "Missing or invalid parameter(s)"
    end
  end

  describe "DELETE /sourcecast, staff" do
    @tag authenticate: :staff
    test "successful", %{conn: conn} do
      %{sourcecasts: sourcecasts} = seed_db()
      sourcecast = List.first(sourcecasts)

      conn = delete(conn, build_url(sourcecast.id), %{})

      assert response(conn, 200) =~ "OK"
    end
  end

  describe "POST /sourcecast, admin" do
    @tag authenticate: :admin
    test "successful", %{conn: conn} do
      conn =
        post(conn, build_url(), %{
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
      conn = post(conn, build_url(), %{})
      assert response(conn, 400) =~ "Missing or invalid parameter(s)"
    end
  end

  describe "DELETE /sourcecast, admin" do
    @tag authenticate: :admin
    test "successful", %{conn: conn} do
      %{sourcecasts: sourcecasts} = seed_db()
      sourcecast = List.first(sourcecasts)

      conn = delete(conn, build_url(sourcecast.id), %{})

      assert response(conn, 200) =~ "OK"
    end
  end

  defp build_url, do: "/v1/sourcecast/"
  defp build_url(sourcecast_id), do: "#{build_url()}#{sourcecast_id}/"

  defp seed_db do
    sourcecasts =
      for i <- 0..4 do
        insert(:sourcecast, %{
          title: "Title#{i}",
          description: "Description#{i}",
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
