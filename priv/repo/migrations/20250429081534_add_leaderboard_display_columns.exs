defmodule Cadet.Repo.Migrations.AddLeaderboardDisplayColumns do
  use Ecto.Migration

  def up do
    alter table(:courses) do
      add(:enable_overall_leaderboard, :boolean, null: false, default: true)
      add(:enable_contest_leaderboard, :boolean, null: false, default: true)
      add(:top_leaderboard_display, :integer, default: 100)
      add(:top_contest_leaderboard_display, :integer, default: 10)
    end

    execute("""
      UPDATE courses
      SET enable_overall_leaderboard = false, enable_contest_leaderboard = false
    """)
  end

  def down do
    alter table(:courses) do
      remove(:enable_overall_leaderboard)
      remove(:enable_contest_leaderboard)
      remove(:top_leaderboard_display)
      remove(:top_contest_leaderboard_display)
    end
  end
end
