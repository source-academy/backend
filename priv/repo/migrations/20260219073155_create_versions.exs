defmodule Cadet.Repo.Migrations.CreateVersions do
  use Ecto.Migration
  import Ecto.Query, only: [from: 2]

  def change do
    create table(:versions) do
      add(:version, :map)
      add(:name, :string)
      add(:restored, :boolean, default: false, null: false)
      add(:answer_id, references(:answers, on_delete: :delete_all))
      add(:restored_from, references(:versions, on_delete: :nothing))

      timestamps()
    end

    create(index(:versions, [:answer_id]))
    create(index(:versions, [:restored_from]))

    # Backfill data from answers table
    execute(fn ->
      answers =
        from(a in "answers",
          select: %{
            id: a.id,
            answer: a.answer,
            inserted_at: a.inserted_at,
            updated_at: a.updated_at
          },
          join: q in "questions",
          on: q.id == a.question_id,
          where: q.type != "voting"
        )
        |> repo().all()

      versions =
        answers
        |> Enum.map(fn a ->
          %{
            answer_id: a.id,
            version: a.answer,
            inserted_at: a.inserted_at,
            updated_at: a.updated_at
          }
        end)

      repo().insert_all("versions", versions)
    end)
  end
end
