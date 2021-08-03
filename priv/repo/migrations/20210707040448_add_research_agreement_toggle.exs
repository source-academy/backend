defmodule Cadet.Repo.Migrations.AddResearchAgreementToggle do
  use Ecto.Migration

  def change do
    alter table(:course_registrations) do
      add(:agreed_to_research, :boolean, null: true)
    end
  end
end
