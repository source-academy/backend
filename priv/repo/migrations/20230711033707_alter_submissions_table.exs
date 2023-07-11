defmodule Cadet.Repo.Migrations.AlterSubmissionsTable do
  use Ecto.Migration

  def up do
    # Drop the existing constraint
    execute("ALTER TABLE submissions DROP CONSTRAINT IF EXISTS submissions_student_id_fkey;")

    alter table(:submissions) do
      modify(:student_id, references(:users), null: true)
      add(:team_id, references(:teams), null: true)
    end

    execute("ALTER TABLE submissions ADD CONSTRAINT xor_constraint CHECK (
      (student_id IS NULL AND team_id IS NOT NULL) OR
      (student_id IS NOT NULL AND team_id IS NULL)
    );")
  end

  def down do
    execute("ALTER TABLE submissions DROP CONSTRAINT xor_constraint;")

    alter table(:submissions) do
      modify(:student_id, references(:users), null: false)
      drop(:team_id)
    end
  end
end
