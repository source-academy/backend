defmodule Cadet.Repo.Migrations.AddAvengerBacklogNotificationType do
  use Ecto.Migration

  def up do
    execute(
      "INSERT INTO notification_types (name, template_file_name, is_autopopulated, inserted_at, updated_at) VALUES ('AVENGER BACKLOG', 'avenger_backlog', TRUE, current_timestamp, current_timestamp)"
    )
  end

  def down do
    execute("DELETE FROM notification_types WHERE name = 'AVENGER BACKLOG'")
  end
end
