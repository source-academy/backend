defmodule Cadet.Repo.Migrations.AddPixelbotModelToCourses do
  use Ecto.Migration

  def up do
    alter table(:courses) do
      add(:pixelbot_model, :string, null: true)
    end
  end

  def down do
    alter table(:courses) do
      remove(:pixelbot_model)
    end
  end
end
