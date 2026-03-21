defmodule Cadet.Repo.Migrations.RepairLlmColumnsOnAssessments do
  use Ecto.Migration

  def up do
    alter table(:assessments) do
      add_if_not_exists(:llm_input_cost, :decimal, precision: 10, scale: 4)
      add_if_not_exists(:llm_output_cost, :decimal, precision: 10, scale: 4)
      add_if_not_exists(:llm_total_input_tokens, :integer, default: 0)
      add_if_not_exists(:llm_total_output_tokens, :integer, default: 0)
      add_if_not_exists(:llm_total_cached_tokens, :integer, default: 0)
      add_if_not_exists(:llm_total_cost, :decimal, precision: 10, scale: 4, default: 0.0)
    end
  end

  def down do
    alter table(:assessments) do
      remove(:llm_input_cost)
      remove(:llm_output_cost)
      remove(:llm_total_input_tokens)
      remove(:llm_total_output_tokens)
      remove(:llm_total_cached_tokens)
      remove(:llm_total_cost)
    end
  end
end
