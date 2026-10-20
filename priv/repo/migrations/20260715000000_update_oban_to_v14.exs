defmodule Cadet.Repo.Migrations.UpdateObanToV14 do
  use Ecto.Migration

  def up do
    Oban.Migrations.up(version: 14)
  end

  # `down/1` is inclusive of the given version, so roll back down to (and
  # including) v12 to leave the database at the v11 schema that the previous
  # migration set up.
  def down do
    Oban.Migrations.down(version: 12)
  end
end
