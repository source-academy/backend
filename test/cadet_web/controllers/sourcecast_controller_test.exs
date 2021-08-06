defmodule CadetWeb.SourcecastControllerTest do
  use CadetWeb.ConnCase

  import Ecto.Query

  alias Cadet.Repo
  alias Cadet.Courses.Course
  alias CadetWeb.SourcecastController

  test "swagger" do
    SourcecastController.swagger_definitions()
    SourcecastController.swagger_path_index(nil)
  end

  # describe "GET /v2/sourcecast, unauthenticated" do
  #   test "renders a list of all sourcecast entries for public (those without course_id)", %{
  #     conn: conn
  #   } do
  #     %{sourcecasts: sourcecasts} = seed_db()
  #     course = insert(:course)
  #     seed_db(course.id)

  #     expected =
  #       sourcecasts
  #       |> Enum.map(
  #         &%{
  #           "id" => &1.id,
  #           "title" => &1.title,
  #           "description" => &1.description,
  #           "uid" => &1.uid,
  #           "playbackData" => &1.playbackData,
  #           "uploader" => %{
  #             "name" => &1.uploader.name,
  #             "id" => &1.uploader.id
  #           },
  #           "url" => Cadet.Courses.SourcecastUpload.url({&1.audio, &1}),
  #           "courseId" => nil
  #         }
  #       )

  #     res =
  #       conn
  #       |> get(build_url())
  #       |> json_response(200)
  #       |> Enum.map(&Map.delete(&1, "audio"))
  #       |> Enum.map(&Map.delete(&1, "inserted_at"))
  #       |> Enum.map(&Map.delete(&1, "updated_at"))

  #     assert expected == res
  #   end
  # end

  describe "GET /v2/courses/{course_id}/sourcecast, returns course sourcecasts" do
    @tag authenticate: :student
    test "renders a list of all course sourcecast entries", %{
      conn: conn
    } do
      course_id = conn.assigns[:course_id]
      seed_db()
      %{sourcecasts: sourcecasts} = seed_db(course_id)

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
            "url" => Cadet.Courses.SourcecastUpload.url({&1.audio, &1}),
            "courseId" => course_id
          }
        )

      res =
        conn
        |> get(build_url(course_id))
        |> json_response(200)
        |> Enum.map(&Map.delete(&1, "audio"))
        |> Enum.map(&Map.delete(&1, "inserted_at"))
        |> Enum.map(&Map.delete(&1, "updated_at"))

      assert expected == res
    end
  end

  # defp build_url, do: "/v2/sourcecast/"
  defp build_url(course_id), do: "/v2/courses/#{course_id}/sourcecast/"

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
