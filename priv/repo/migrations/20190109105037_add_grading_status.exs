defmodule Cadet.Repo.Migrations.AddGradingStatus do
  use Ecto.Migration

  alias Cadet.Assessments.GradingStatus

  def change do
    GradingStatus.create_type()
  end
end
