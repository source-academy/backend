defmodule Cadet.Release do
  @moduledoc """
  Contains Release.migrate, to simplify running migrations from the command line
  """
  def migrate do
    Application.load(:cadet)

    Ecto.Migrator.with_repo(
      Cadet.Repo,
      &Ecto.Migrator.run(&1, Application.app_dir(:cadet, "priv/repo/migrations"), :up, all: true)
    )
  end
end
