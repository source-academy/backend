defmodule Cadet.Repo.Migrations.AddLeaderboardDisplayColumns do
  use Ecto.Migration

  def change do
    alter table(:courses) do
      add(:enable_overall_leaderboard, :boolean, null: false, default: true)
      add(:enable_contest_leaderboard, :boolean, null: false, default: true)
      add(:top_leaderboard_display, :integer, default: 100)
      add(:top_contest_leaderboard_display, :integer, default: 10)
    end

    execute(fn ->
      repo().update_all("courses", set: [
        enable_overall_leaderboard: true,
        enable_contest_leaderboard: true,
        top_leaderboard_display: 100,
        top_contest_leaderboard_display: 10
      ])
    end)
  end
end
