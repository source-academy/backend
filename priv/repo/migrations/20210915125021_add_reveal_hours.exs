defmodule Cadet.Repo.Migrations.AddRevealHours do
  use Ecto.Migration

  def change do
    execute("update questions set question = question || jsonb_build_object('reveal_hours', 48)")
  end
end
