defmodule Cadet.Repo.Migrations.RepairLlmColumnsOnAssessments do
  use Ecto.Migration

  def up do
    alter table(:assessments) do
      add_if_not_exists :llm_input_cost, :decimal, precision: 10, scale: 4, default: 3.20
      add_if_not_exists :llm_output_cost, :decimal, precision: 10, scale: 4, default: 12.80
      add_if_not_exists :llm_total_input_tokens, :integer, default: 0
      add_if_not_exists :llm_total_output_tokens, :integer, default: 0
      add_if_not_exists :llm_total_cached_tokens, :integer, default: 0
      add_if_not_exists :llm_total_cost, :decimal, precision: 10, scale: 4, default: 0.0
    end
  end

  def down do
    alter table(:assessments) do
      remove_if_exists :llm_input_cost, :decimal
      remove_if_exists :llm_output_cost, :decimal
      remove_if_exists :llm_total_input_tokens, :integer
      remove_if_exists :llm_total_output_tokens, :integer
      remove_if_exists :llm_total_cached_tokens, :integer
      remove_if_exists :llm_total_cost, :decimal
    end
  end
end
