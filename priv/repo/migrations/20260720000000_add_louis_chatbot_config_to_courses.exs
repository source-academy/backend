defmodule Cadet.Repo.Migrations.AddLouisChatbotConfigToCourses do
  use Ecto.Migration

  def change do
    alter table(:courses) do
      add(:louis_chatbot_prompt, :text, null: true)
      add(:enable_louis_chatbot, :boolean, null: false, default: false)
    end
  end
end
