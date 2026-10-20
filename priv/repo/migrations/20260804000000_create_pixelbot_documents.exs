defmodule Cadet.Repo.Migrations.CreatePixelbotDocuments do
  use Ecto.Migration

  def up do
    create table(:pixelbot_categories) do
      add(:course_id, references(:courses, on_delete: :delete_all), null: false)
      add(:name, :string, null: false)

      timestamps()
    end

    create(unique_index(:pixelbot_categories, [:course_id, :name]))

    create table(:pixelbot_documents) do
      add(:course_id, references(:courses, on_delete: :delete_all), null: false)
      add(:category_id, references(:pixelbot_categories, on_delete: :restrict), null: false)
      add(:doc_key, :string, null: false)
      add(:title, :text, null: false)
      add(:description, :text, null: false, default: "")
      add(:release_date, :date, null: true)
      add(:s3_key, :string, null: false)
      add(:filename, :string, null: false)
      add(:media_type, :string, null: false)

      timestamps()
    end

    create(index(:pixelbot_documents, [:course_id]))
    create(index(:pixelbot_documents, [:category_id]))
    create(unique_index(:pixelbot_documents, [:course_id, :doc_key]))
    create(unique_index(:pixelbot_documents, [:s3_key]))
  end

  def down do
    drop(table(:pixelbot_documents))
    drop(table(:pixelbot_categories))
  end
end
