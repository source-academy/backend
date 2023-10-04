defmodule Cadet.Repo.Migrations.ChangeAvengerBacklogNotificationType do
  use Ecto.Migration

  def up do
    execute(
      "UPDATE notification_types SET is_autopopulated = FALSE WHERE name = 'AVENGER BACKLOG'"
    )
  end

  def down do
    execute(
      "UPDATE notification_types SET is_autopopulated = TRUE WHERE name = 'AVENGER BACKLOG'"
    )
  end
end
