defmodule CadetWeb.Schemas.TeamFormationOverview do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "TeamFormationOverview",
    description: "Overview of a team formation for an assessment",
    type: :object,
    properties: %{
      teamId: %Schema{type: :integer, description: "The id of the team"},
      assessmentId: %Schema{type: :integer, description: "The id of the assessment"},
      assessmentName: %Schema{type: :string, description: "The name of the assessment"},
      assessmentType: %Schema{type: :string, description: "The type of the assessment"},
      studentIds: %Schema{
        type: :array,
        items: %Schema{type: :integer},
        description: "List of student user ids"
      },
      studentNames: %Schema{
        type: :array,
        items: %Schema{type: :string},
        description: "List of student names"
      }
    },
    required: [
      :teamId,
      :assessmentId,
      :assessmentName,
      :assessmentType,
      :studentIds,
      :studentNames
    ]
  })
end
