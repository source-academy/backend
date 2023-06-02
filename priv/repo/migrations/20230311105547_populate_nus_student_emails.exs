defmodule Cadet.Repo.Migrations.PopulateNusStudentEmails do
  use Ecto.Migration

  def change do
    execute("
      update users
      set email = username || '@u.nus.edu'
      where username ~ '^[eE][0-9]{7}$' and email IS NULL and provider = 'luminus';
      ")
  end
end
