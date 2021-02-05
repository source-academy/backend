defmodule Cadet.Repo.Migrations.AdaddVotingQuestionType do
  use Ecto.Migration
  @disable_ddl_transaction true

  def change do
    Ecto.Migration.execute("ALTER TYPE question_type ADD VALUE IF NOT EXISTS 'voting'")
  end
end
