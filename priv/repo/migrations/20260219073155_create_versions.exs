defmodule Cadet.Repo.Migrations.CreateVersions do
  use Ecto.Migration
  import Ecto.Query, only: [from: 2]

  def up do
    create table(:versions) do
      add(:content, :map)
      add(:name, :string)
      add(:answer_id, references(:answers, on_delete: :delete_all))

      timestamps()
    end

    create(index(:versions, [:answer_id]))

    # Backfill data from answers table
    flush()

    source_query =
      from(a in "answers",
        join: q in "questions",
        on: q.id == a.question_id,
        where: q.type == "programming",
        select: %{
          content: a.answer,
          answer_id: a.id,
          inserted_at: a.inserted_at,
          updated_at: a.updated_at
        }
      )

    repo().insert_all("versions", source_query)
  end

  def down do
    drop(table(:versions))
  end
end
