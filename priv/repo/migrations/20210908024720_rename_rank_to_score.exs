defmodule Cadet.Repo.Migrations.RenameRankToScore do
  use Ecto.Migration

  def change do
    rename(table(:submission_votes), :rank, to: :score)
  end
end
