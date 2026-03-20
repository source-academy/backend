defmodule Cadet.Repo.Migrations.RepairLlmColumnsOnAssessments do
  use Ecto.Migration

  def up do
    alter table(:assessments) do
      add_if_missing(:llm_input_cost, :decimal, precision: 10, scale: 4)
      add_if_missing(:llm_output_cost, :decimal, precision: 10, scale: 4)
      add_if_missing(:llm_total_input_tokens, :integer, default: 0)
      add_if_missing(:llm_total_output_tokens, :integer, default: 0)
      add_if_missing(:llm_total_cached_tokens, :integer, default: 0)
      add_if_missing(:llm_total_cost, :decimal, precision: 10, scale: 4, default: 0.0)
    end
  end

  def down do
    alter table(:assessments) do
      remove :llm_input_cost
      remove :llm_output_cost
      remove :llm_total_input_tokens
      remove :llm_total_output_tokens
      remove :llm_total_cached_tokens
      remove :llm_total_cost
    end
  end

  defp add_if_missing(column, type, opts) do
    # Direct check against the database metadata
    query = "SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'assessments' AND column_name = '#{column}')"

    case repo().query!(query) do
      %{rows: [[false]]} -> add column, type, opts
      _ -> :ok
    end
  end
end
