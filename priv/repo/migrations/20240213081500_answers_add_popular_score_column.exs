defmodule Cadet.Repo.Migrations.AnswersAddPopularScoreColumn do
  use Ecto.Migration

  def change do
    alter table("answers") do
      add(:popular_score, :float, default: 0.0)
    end
  end
end
