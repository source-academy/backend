defmodule CadetWeb.Schemas.AdminSublanguage do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema
  alias CadetWeb.Schemas.SourceVariant

  OpenApiSpex.schema(%{
    title: "AdminSublanguage",
    description: "The default Source chapter and variant for a course",
    type: :object,
    properties: %{
      chapter: %Schema{type: :integer, minimum: 1, maximum: 4, description: "Chapter (1-4)"},
      variant: SourceVariant
    },
    required: [:chapter, :variant],
    example: %{chapter: 2, variant: "lazy"}
  })
end

defmodule CadetWeb.Schemas.UpdateCourseConfigRequest do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema
  alias CadetWeb.Schemas.AdminSublanguage

  # A partial update -- every field is optional.
  OpenApiSpex.schema(%{
    title: "UpdateCourseConfigRequest",
    description: "Request body for updating a course's configuration (all fields optional)",
    type: :object,
    properties: %{
      courseName: %Schema{type: :string},
      courseShortName: %Schema{type: :string},
      viewable: %Schema{type: :boolean},
      enableGame: %Schema{type: :boolean},
      enableAchievements: %Schema{type: :boolean},
      enableOverallLeaderboard: %Schema{type: :boolean},
      enableContestLeaderboard: %Schema{type: :boolean},
      topLeaderboardDisplay: %Schema{type: :integer},
      topContestLeaderboardDisplay: %Schema{type: :integer},
      enableSourcecast: %Schema{type: :boolean},
      enableStories: %Schema{type: :boolean},
      enableLlmGrading: %Schema{type: :boolean},
      llmApiKey: %Schema{type: :string, description: "OpenAI API key for this course"},
      sublanguage: AdminSublanguage,
      moduleHelpText: %Schema{type: :string}
    }
  })
end

defmodule CadetWeb.Schemas.UpdateAssessmentConfigsRequest do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema
  alias CadetWeb.Schemas.AssessmentConfiguration

  # `assessmentConfigs` is validated by the action (which checks it is a list of
  # config objects and returns its own errors), so its type is not enforced here.
  OpenApiSpex.schema(%{
    title: "UpdateAssessmentConfigsRequest",
    description: "Request body for replacing the course's assessment configurations",
    type: :object,
    properties: %{
      assessmentConfigs: %Schema{
        description: "List of assessment configuration objects",
        items: AssessmentConfiguration
      }
    }
  })
end

defmodule CadetWeb.Schemas.DocumentMapResponse do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "DocumentMapResponse",
    description: "The Pixelbot document map for the course",
    type: :object,
    properties: %{documentMap: %Schema{type: :object, description: "The document map"}},
    required: [:documentMap]
  })
end
