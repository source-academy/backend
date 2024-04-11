defmodule MyApp.Repo.Migrations.UpdateIsGradingPublished do
  use Ecto.Migration

  def up do
    execute("""
      UPDATE submissions
      SET is_grading_published = true
      WHERE id IN (
        SELECT s.id
        FROM submissions AS s
        JOIN answers AS a ON a.submission_id = s.id
        GROUP BY s.id
        HAVING COUNT(a.id) = COUNT(a.grader_id)
      )
    """)
  end

  def down do
    execute("""
      UPDATE submissions
      SET is_grading_published = false
    """)
  end
end
