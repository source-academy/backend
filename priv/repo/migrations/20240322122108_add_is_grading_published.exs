defmodule Cadet.Repo.Migrations.AddIsGradingPublished do
  use Ecto.Migration

  def change do
    alter table(:submissions) do
      add(:is_grading_published, :boolean, null: false, default: false)
    end
  end
end
