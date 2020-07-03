defmodule Cadet.Repo.Migrations.RefactorDefaultChapter do
  use Ecto.Migration

  def change do
    rename(table(:chapters), to: table(:sublanguages))
    rename(table(:sublanguages), :chapterno, to: :chapter)
  end
end
