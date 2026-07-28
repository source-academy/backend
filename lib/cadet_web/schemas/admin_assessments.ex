defmodule CadetWeb.Schemas.CreateAssessmentRequest do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "CreateAssessmentRequest",
    description: "Multipart request body for creating or updating an assessment from XML",
    type: :object,
    properties: %{
      assessment: %Schema{type: :string, format: :binary, description: "The assessment XML file"},
      forceUpdate: %Schema{type: :string, description: "\"true\" to force update"},
      assessmentConfigId: %Schema{type: :integer, description: "Assessment config id"}
    },
    required: [:assessment, :forceUpdate, :assessmentConfigId]
  })
end

defmodule CadetWeb.Schemas.UpdateAssessmentRequest do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  # All fields optional -- a partial update.
  OpenApiSpex.schema(%{
    title: "UpdateAssessmentRequest",
    description: "Request body for updating an assessment (all fields optional)",
    type: :object,
    properties: %{
      openAt: %Schema{type: :string, format: :"date-time"},
      closeAt: %Schema{type: :string, format: :"date-time"},
      isPublished: %Schema{type: :boolean},
      maxTeamSize: %Schema{type: :integer},
      hasTokenCounter: %Schema{type: :boolean},
      hasVotingFeatures: %Schema{type: :boolean},
      isAutosaveEnabled: %Schema{type: :boolean},
      assignEntriesForVoting: %Schema{type: :boolean}
    }
  })
end
