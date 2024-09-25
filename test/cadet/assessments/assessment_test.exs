defmodule Cadet.Assessments.AssessmentTest do
  alias Cadet.Assessments.Assessment

  use Cadet.ChangesetCase, entity: Assessment

  setup do
    course1 = insert(:course, %{course_short_name: "course 1"})
    course2 = insert(:course, %{course_short_name: "course 2"})
    config1 = insert(:assessment_config, %{course: course1})
    config2 = insert(:assessment_config, %{course: course2})

    {:ok, %{course1: course1, course2: course2, config1: config1, config2: config2}}
  end

  describe "Changesets" do
    test "valid changesets", %{
      course1: course1,
      course2: course2,
      config1: config1,
      config2: config2
    } do
      assert_changeset(
        %{
          config_id: config1.id,
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
          config_id: config2.id,
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

    test "invalid changesets missing required params", %{course1: course1, config1: config1} do
      assert_changeset(
        %{
          config_id: config1.id,
          course_id: course1.id,
          title: "mission",
          number: "M#{Enum.random(0..10)}"
        },
        :invalid
      )

      assert_changeset(
        %{
          config_id: config1.id,
          course_id: course1.id,
          title: "mission",
          open_at: Timex.now() |> Timex.to_unix() |> Integer.to_string(),
          close_at: Timex.now() |> Timex.shift(days: 7) |> Timex.to_unix() |> Integer.to_string()
        },
        :invalid
      )
    end

    test "invalid changesets due to config_course", %{
      course1: course1,
      config1: config1,
      config2: config2
    } do
      config_not_in_course =
        Assessment.changeset(%Assessment{}, %{
          config_id: config2.id,
          course_id: course1.id,
          title: "mission",
          number: "4",
          open_at: Timex.now(),
          close_at: Timex.shift(Timex.now(), days: 7)
        })

      {:error, changeset} = Repo.insert(config_not_in_course)

      assert changeset.errors == [
               {:config, {"does not belong to the same course as this assessment", []}}
             ]

      refute changeset.valid?

      config_not_exist =
        Assessment.changeset(%Assessment{}, %{
          config_id: config1.id + config2.id,
          course_id: course1.id,
          title: "invalid config",
          number: "M#{Enum.random(1..10)}",
          open_at: Timex.now() |> Timex.to_unix() |> Integer.to_string(),
          close_at:
            Timex.now()
            |> Timex.shift(days: Enum.random(1..7))
            |> Timex.to_unix()
            |> Integer.to_string()
        })

      {:error, changeset2} = Repo.insert(config_not_exist)
      assert changeset2.errors == [{:config, {"does not exist", []}}]
      refute changeset2.valid?
    end

    test "invalid changesets due to invalid dates", %{course1: course1, config1: config1} do
      invalid_date =
        Assessment.changeset(%Assessment{}, %{
          config_id: config1.id,
          course_id: course1.id,
          title: "mission",
          number: "4",
          open_at: Timex.shift(Timex.now(), days: 7),
          close_at: Timex.now()
        })

      {:error, changeset} = Repo.insert(invalid_date)
      assert changeset.errors == [{:open_at, {"Open date must be before close date", []}}]
      refute changeset.valid?
    end

    test "invalid changeset with invalid team size", %{
      course1: course1,
      config1: config1
    } do
      changeset =
        Assessment.changeset(%Assessment{}, %{
          config_id: config1.id,
          course_id: course1.id,
          title: "mission",
          number: "M#{Enum.random(0..10)}",
          max_team_size: -1,
          open_at: Timex.now() |> Timex.to_unix() |> Integer.to_string(),
          close_at: Timex.now() |> Timex.shift(days: 7) |> Timex.to_unix() |> Integer.to_string()
        })

      assert changeset.valid? == false

      assert changeset.errors[:max_team_size] ==
               {"must be greater than or equal to %{number}",
                [validation: :number, kind: :greater_than_or_equal_to, number: 1]}
    end
  end
end
