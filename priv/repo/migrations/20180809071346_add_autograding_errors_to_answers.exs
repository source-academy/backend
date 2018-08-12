defmodule Cadet.Repo.Migrations.AddAutogradingErrorsToAnswers do
  use Ecto.Migration

  def change do
    alter table(:answers) do
      add(:autograding_errors, {:array, :map}, null: false, default: [])
    end
  end
end
