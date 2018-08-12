defmodule Cadet.Repo.Migrations.AddAutogradingFields do
  use Ecto.Migration

  alias Cadet.Assessments.Answer.AutogradingStatus

  def up do
    AutogradingStatus.create_type()

    alter table(:answers) do
      add(:autograding_status, :autograding_status, null: false, default: "none")
    end
  end

  def down do
    alter table(:answers) do
      remove(:autograding_status)
    end

    AutogradingStatus.drop_type()
  end
end
