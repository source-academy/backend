defmodule Cadet.Repo.Migrations.AddXpToAssessments do
  use Ecto.Migration

  def change do
    alter table(:questions) do
      add(:max_xp, :integer, default: 0)
    end

    alter table(:submissions) do
      add(:xp_bonus, :integer, default: 0)
    end

    alter table(:answers) do
      add(:xp, :integer, default: 0)
      add(:xp_adjustment, :integer, default: 0)
    end
  end
end
