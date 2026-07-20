defmodule CadetWeb.Schemas.Goal do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "Goal",
    description: "A goal definition",
    type: :object,
    properties: %{
      uuid: %Schema{type: :string, format: :uuid, description: "Goal UUID"},
      text: %Schema{type: :string, description: "Text shown for the goal"},
      targetCount: %Schema{
        type: :integer,
        description: "When progress reaches this number, the goal is completed"
      },
      type: %Schema{type: :string, description: "Goal type"},
      meta: %Schema{type: :object, description: "Goal satisfaction information"}
    },
    required: [:uuid, :text, :targetCount, :type]
  })
end

defmodule CadetWeb.Schemas.GoalInput do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "GoalInput",
    description: "A goal to insert, or a set of properties to update",
    type: :object,
    properties: %{
      uuid: %Schema{type: :string, format: :uuid, description: "Goal UUID (optional on update)"},
      text: %Schema{type: :string, description: "Text shown for the goal"},
      targetCount: %Schema{type: :integer, description: "Target count for completion"},
      type: %Schema{type: :string, description: "Goal type"},
      meta: %Schema{type: :object, description: "Goal satisfaction information"}
    },
    required: [:text, :targetCount, :type]
  })
end

defmodule CadetWeb.Schemas.UpdateGoalRequest do
  @moduledoc false
  require OpenApiSpex
  alias CadetWeb.Schemas.GoalInput

  OpenApiSpex.schema(%{
    title: "UpdateGoalRequest",
    description: "Request body for inserting or updating a single goal",
    type: :object,
    properties: %{goal: GoalInput},
    required: [:goal]
  })
end

defmodule CadetWeb.Schemas.BulkUpdateGoalsRequest do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema
  alias CadetWeb.Schemas.GoalInput

  OpenApiSpex.schema(%{
    title: "BulkUpdateGoalsRequest",
    description: "Request body for inserting or updating multiple goals",
    type: :object,
    properties: %{goals: %Schema{type: :array, items: GoalInput}},
    required: [:goals]
  })
end
