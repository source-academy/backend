defmodule Cadet.Repo.Migrations.AddIvleToAccounts do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove(:first_name)
      remove(:last_name)
      add(:name, :string)
    end
  end
end
