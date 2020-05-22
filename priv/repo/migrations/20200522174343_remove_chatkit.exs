defmodule Cadet.Repo.Migrations.RemoveChatkit do
  use Ecto.Migration

  def change do
    alter table(:answers) do
      remove(:room_id)
    end
  end
end
