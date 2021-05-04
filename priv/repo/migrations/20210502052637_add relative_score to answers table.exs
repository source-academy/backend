defmodule :"Elixir.Cadet.Repo.Migrations.Add relativeScore to answers table" do
  use Ecto.Migration

  def change do
    alter table(:answers) do
      add(:relative_score, :float, default: 0.0)
    end
  end
end
