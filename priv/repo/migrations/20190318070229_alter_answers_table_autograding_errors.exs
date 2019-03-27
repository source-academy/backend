defmodule Cadet.Repo.Migrations.AlterAnswersTableAutogradingErrors do
  use Ecto.Migration

  def change do
    rename(table(:answers), :autograding_errors, to: :autograding_results)
  end
end
