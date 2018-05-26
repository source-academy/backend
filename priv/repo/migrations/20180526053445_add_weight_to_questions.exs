defmodule Cadet.Repo.Migrations.AddWeightToQuestions do
  use Ecto.Migration

  def change do
    alter table(:questions) do
      add(:weight, :integer)
    end
  end
end
