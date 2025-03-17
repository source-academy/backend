defmodule Cadet.Courses.CourseTest do
  alias Cadet.Courses.Course

  use Cadet.ChangesetCase, entity: Course

  describe "Course Configuration Changesets" do
    test "valid changesets" do
      assert_changeset(
        %{
          course_name: "Data Structures and Algorithms",
          source_chapter: 1,
          source_variant: "default",
          top_leaderboard_display: 100,
          top_contest_leaderboard_display: 10
        },
        :valid
      )

      assert_changeset(
        %{
          course_short_name: "CS2040S",
          course_name: "Data Structures and Algorithms",
          source_chapter: 1,
          source_variant: "default",
          top_leaderboard_display: 100,
          top_contest_leaderboard_display: 10
        },
        :valid
      )

      assert_changeset(
        %{
          viewable: false,
          course_name: "Data Structures and Algorithms",
          source_chapter: 1,
          source_variant: "default",
          top_leaderboard_display: 100,
          top_contest_leaderboard_display: 10
        },
        :valid
      )

      assert_changeset(
        %{
          enable_game: false,
          course_name: "Data Structures and Algorithms",
          source_chapter: 1,
          source_variant: "default",
          top_leaderboard_display: 100,
          top_contest_leaderboard_display: 10
        },
        :valid
      )

      assert_changeset(
        %{
          enable_achievements: false,
          course_name: "Data Structures and Algorithms",
          source_chapter: 1,
          source_variant: "default",
          top_leaderboard_display: 100,
          top_contest_leaderboard_display: 10
        },
        :valid
      )

      assert_changeset(
        %{
          enable_sourcecast: false,
          course_name: "Data Structures and Algorithms",
          source_chapter: 1,
          source_variant: "default",
          top_leaderboard_display: 100,
          top_contest_leaderboard_display: 10
        },
        :valid
      )

      assert_changeset(
        %{
          module_help_text: "",
          course_name: "Data Structures and Algorithms",
          source_chapter: 1,
          source_variant: "default",
          top_leaderboard_display: 100,
          top_contest_leaderboard_display: 10
        },
        :valid
      )

      assert_changeset(
        %{
          module_help_text: "Module help text",
          course_name: "Data Structures and Algorithms",
          source_chapter: 1,
          source_variant: "default",
          top_leaderboard_display: 100,
          top_contest_leaderboard_display: 10
        },
        :valid
      )

      assert_changeset(
        %{
          enable_game: true,
          enable_achievements: true,
          enable_sourcecast: true,
          course_name: "Data Structures and Algorithms",
          source_chapter: 1,
          source_variant: "default",
          top_leaderboard_display: 100,
          top_contest_leaderboard_display: 10
        },
        :valid
      )

      assert_changeset(
        %{
          enable_game: true,
          enable_achievements: true,
          enable_sourcecast: true,
          enable_stories: false,
          course_name: "Data Structures and Algorithms",
          source_chapter: 1,
          source_variant: "default",
          top_leaderboard_display: 100,
          top_contest_leaderboard_display: 10
        },
        :valid
      )

      assert_changeset(
        %{
          source_chapter: 1,
          source_variant: "wasm",
          course_name: "Data Structures and Algorithms",
          top_leaderboard_display: 100,
          top_contest_leaderboard_display: 10
        },
        :valid
      )

      assert_changeset(
        %{
          source_chapter: 2,
          source_variant: "lazy",
          course_name: "Data Structures and Algorithms",
          top_leaderboard_display: 100,
          top_contest_leaderboard_display: 10
        },
        :valid
      )

      assert_changeset(
        %{
          source_chapter: 3,
          source_variant: "non-det",
          course_name: "Data Structures and Algorithms",
          top_leaderboard_display: 100,
          top_contest_leaderboard_display: 10
        },
        :valid
      )

      assert_changeset(
        %{
          source_chapter: 3,
          source_variant: "native",
          course_name: "Data Structures and Algorithms",
          top_leaderboard_display: 100,
          top_contest_leaderboard_display: 10
        },
        :valid
      )

      assert_changeset(
        %{
          source_chapter: 2,
          source_variant: "typed",
          course_name: "Data Structures and Algorithms",
          top_leaderboard_display: 100,
          top_contest_leaderboard_display: 10
        },
        :valid
      )

      assert_changeset(
        %{
          source_chapter: 4,
          source_variant: "default",
          enable_achievements: true,
          course_name: "Data Structures and Algorithms",
          top_leaderboard_display: 100,
          top_contest_leaderboard_display: 10
        },
        :valid
      )

      assert_changeset(
        %{
          course_name: "Data Structures and Algorithms",
          source_chapter: 1,
          source_variant: "default",
          top_leaderboard_display: 200,
          top_contest_leaderboard_display: 10
        },
        :valid
      )

      assert_changeset(
        %{
          course_name: "Data Structures and Algorithms",
          source_chapter: 1,
          source_variant: "default",
          top_leaderboard_display: 350,
          top_contest_leaderboard_display: 10
        },
        :valid
      )
    end

    test "invalid changeset missing required params" do
      assert_changeset(%{source_chapter: 2}, :invalid)
      assert_changeset(%{source_variant: "default"}, :invalid)
    end

    test "invalid changeset with invalid chapter" do
      assert_changeset(%{source_chapter: 5, source_variant: "default"}, :invalid)
    end

    test "invalid changeset with invalid variant" do
      assert_changeset(%{source_chapter: Enum.random(1..4), source_variant: "error"}, :invalid)
    end

    test "invalid changeset with invalid chapter-variant combination" do
      assert_changeset(%{source_chapter: 4, source_variant: "lazy"}, :invalid)
    end
  end
end
