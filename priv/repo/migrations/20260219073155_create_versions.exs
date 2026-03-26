defmodule Cadet.Repo.Migrations.CreateVersions do
  use Ecto.Migration
  import Ecto.Query, only: [from: 2]

  def up do
    create table(:versions) do
      add(:content, :map)
      add(:name, :string)
      add(:restored, :boolean, default: false, null: false)
      add(:answer_id, references(:answers, on_delete: :delete_all))
      add(:restored_from, references(:versions, on_delete: :nothing))

      timestamps()
    end

    create(index(:versions, [:answer_id]))
    create(index(:versions, [:restored_from]))

    # Backfill data from answers table
    flush()

    source_query =
      from(a in "answers",
        join: q in "questions",
        on: q.id == a.question_id,
        where: q.type != "voting",
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
