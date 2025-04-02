defmodule Cadet.Repo.Migrations.CreateNotebooks do
  use Ecto.Migration

  def change do
    create table(:notebooks) do
      add(:title, :string, null: false)
      add(:config, :string)
      add(:is_published, :boolean, default: false)
      add(:pin_order, :integer)

      # Foreign keys
      add(:course, references(:courses), null: false)
      add(:user, references(:users), null: false)
      add(:course_registration, references(:course_registrations), null: false)

      timestamps()
    end

    create(index(:notebooks, [:course_registration]))
    create(index(:notebooks, [:user]))
    create(index(:notebooks, [:course]))
    create(index(:notebooks, [:is_published]))
  end
end
