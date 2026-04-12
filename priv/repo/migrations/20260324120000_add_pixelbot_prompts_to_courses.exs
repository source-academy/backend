defmodule Cadet.Repo.Migrations.AddPixelbotPromptsToCourses do
  use Ecto.Migration

  def up do
    alter table(:courses) do
      add(:pixelbot_routing_prompt, :text, null: true)
      add(:pixelbot_answer_prompt, :text, null: true)
    end
  end

  def down do
    alter table(:courses) do
      remove(:pixelbot_routing_prompt)
      remove(:pixelbot_answer_prompt)
    end
  end
end
