defmodule Cadet.Repo.Migrations.CreateUserBrowserFocusLogTable do
  use Ecto.Migration

  def change do
    create table(:user_browser_focus_log) do
      add(:user_id, references(:users), null: false)
      add(:course_id, references(:courses), null: false)
      add(:time, :naive_datetime, null: false)
      add(:focus_type, :integer, null: false)
    end
  end
end
