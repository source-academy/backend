defmodule Cadet.Repo.Migrations.AlterAnswersTableComment do
  use Ecto.Migration

  def change do
    rename(table(:answers), :comment, to: :room_id)
  end
end
