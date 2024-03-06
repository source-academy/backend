defmodule Cadet.Repo.Migrations.RenameHasTokenCounter do
  use Ecto.Migration

  def change do
    rename(table(:assessment_configs), :has_token_counter, to: :is_contest_related)
  end
end
