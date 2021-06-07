defmodule Cadet.Assessments.AssessmentTest do
  alias Cadet.Assessments.Assessment

  use Cadet.ChangesetCase, entity: Assessment

  setup do
    course1 = insert(:course, %{module_code: "course 1"})
    course2 = insert(:course, %{module_code: "course 2"})
    type1 = insert(:assessment_types, %{course: course1})
    type2 = insert(:assessment_types, %{course: course2})

    {:ok, %{course1: course1, course2: course2, type1: type1, type2: type2}}
  end

  describe "Changesets" do
    test "valid changesets", %{course1: course1, course2: course2, type1: type1, type2: type2} do
      assert_changeset(
        %{
          type_id: type1.id,
          course_id: course1.id,
          title: "mission",
          number: "M#{Enum.random(0..10)}",
          open_at: Timex.now() |> Timex.to_unix() |> Integer.to_string(),
          close_at: Timex.now() |> Timex.shift(days: 7) |> Timex.to_unix() |> Integer.to_string()
        },
        :valid
      )

      assert_changeset(
        %{
          type_id: type2.id,
          course_id: course2.id,
          title: "mission",
          number: "M#{Enum.random(0..10)}",
          open_at: Timex.now() |> Timex.to_unix() |> Integer.to_string(),
          close_at: Timex.now() |> Timex.shift(days: 7) |> Timex.to_unix() |> Integer.to_string(),
          cover_picture: Faker.Avatar.image_url(),
          mission_pdf: build_upload("test/fixtures/upload.pdf", "application/pdf")
        },
        :valid
      )
    end

    test "invalid changesets missing required params", %{course1: course1, type1: type1} do
      assert_changeset(
        %{
          type_id: type1.id,
          course_id: course1.id,
          title: "mission",
          number: "M#{Enum.random(0..10)}",
        },
        :invalid
      )
      assert_changeset(
        %{
          type_id: type1.id,
          course_id: course1.id,
          title: "mission",
          open_at: Timex.now() |> Timex.to_unix() |> Integer.to_string(),
          close_at: Timex.now() |> Timex.shift(days: 7) |> Timex.to_unix() |> Integer.to_string()
        },
        :invalid
      )
    end

    test "invalid changesets due to type_course", %{course1: course1, type1: type1, type2: type2} do
      type_not_in_course = Assessment.changeset(%Assessment{}, %{
        type_id: type2.id,
        course_id: course1.id,
        title: "mission",
        number: "4",
        open_at: Timex.now(),
        close_at: Timex.shift(Timex.now(), days: 7),
      })
      {:error, changeset} = Repo.insert(type_not_in_course)
      assert changeset.errors == [{:type, {"does not belong to the same course as this assessment", []}}]
      refute changeset.valid?


      type_not_exist = Assessment.changeset(%Assessment{}, %{
        type_id: type1.id + type2.id,
        course_id: course1.id,
        title: "invalid type",
        number: "M#{Enum.random(1..10)}",
        open_at: Timex.now() |> Timex.to_unix() |> Integer.to_string(),
        close_at:
          Timex.now()
          |> Timex.shift(days: Enum.random(1..7))
          |> Timex.to_unix()
          |> Integer.to_string()
      })
      {:error, changeset2} = Repo.insert(type_not_exist)
      assert changeset2.errors == [{:type, {"does not exist", []}}]
      refute changeset2.valid?
    end

    test "invalid changesets due to invalid dates", %{course1: course1, type1: type1} do
      invalid_date = Assessment.changeset(%Assessment{}, %{
        type_id: type1.id,
        course_id: course1.id,
        title: "mission",
        number: "4",
        open_at: Timex.shift(Timex.now(), days: 7),
        close_at: Timex.now(),
      })
      {:error, changeset} = Repo.insert(invalid_date)
      assert changeset.errors == [{:open_at, {"Open date must be before close date", []}}]
      refute changeset.valid?
    end
  end
  # describe "Changesets" do
  #   test "valid changesets" do
  #     assert_changeset(
  #       %{
  #         type_id: "mission",
  #         course_id:
  #         title: "mission",
  #         number: "M#{Enum.random(0..10)}",
  #         open_at: Timex.now() |> Timex.to_unix() |> Integer.to_string(),
  #         close_at: Timex.now() |> Timex.shift(days: 7) |> Timex.to_unix() |> Integer.to_string()
  #       },
  #       :valid
  #     )

  #     assert_changeset(
  #       %{
  #         type: Enum.random(Assessment.assessment_types()),
  #         title: "mission",
  #         number: "M#{Enum.random(0..10)}",
  #         open_at: Timex.now() |> Timex.to_unix() |> Integer.to_string(),
  #         close_at: Timex.now() |> Timex.shift(days: 7) |> Timex.to_unix() |> Integer.to_string(),
  #         cover_picture: Faker.Avatar.image_url(),
  #         mission_pdf: build_upload("test/fixtures/upload.pdf", "application/pdf")
  #       },
  #       :valid
  #     )
  #   end

  #   test "invalid changesets" do
  #     assert_changeset(%{type: "mission", title: "mission", max_grade: 100}, :invalid)

  #     assert_changeset(
  #       %{
  #         title: "mission",
  #         open_at: Timex.now(),
  #         close_at: Timex.shift(Timex.now(), days: 7),
  #         max_grade: 100
  #       },
  #       :invalid
  #     )

  #     assert_changeset(
  #       %{
  #         type: "misc",
  #         title: "invalid type",
  #         number: "M#{Enum.random(1..10)}",
  #         open_at: Timex.now() |> Timex.to_unix() |> Integer.to_string(),
  #         close_at:
  #           Timex.now()
  #           |> Timex.shift(days: Enum.random(1..7))
  #           |> Timex.to_unix()
  #           |> Integer.to_string()
  #       },
  #       :invalid
  #     )
  #   end
  # end
end
