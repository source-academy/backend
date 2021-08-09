defmodule Cadet.Repo.Migrations.AlterModuleHelpText do
  use Ecto.Migration

  def change do
    alter table(:courses) do
      modify(:module_help_text, :text, from: :string)
    end
  end
end
