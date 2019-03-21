defmodule Cadet.Repo.Migrations.AlterAnswersTableAutogradingErrors do
  use Ecto.Migration

  def up do
    alter table(:answers) do
      add(:autograding_summary, :map)
      remove(:autograding_errors)
    end

  end

  def down do
    alter table(:answers) do
      remove(:autograding_summary)
      add(:autograding_errors, {:array, :map})
    end
  end
end
