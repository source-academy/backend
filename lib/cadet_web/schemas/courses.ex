defmodule CadetWeb.Schemas.SourceVariant do
  @moduledoc false
  require OpenApiSpex

  OpenApiSpex.schema(%{
    title: "SourceVariant",
    description: "A Source language variant",
    type: :string,
    enum: ["default", "concurrent", "gpu", "lazy", "non-det", "wasm"]
  })
end

defmodule CadetWeb.Schemas.CourseConfiguration do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema
  alias CadetWeb.Schemas.SourceVariant

  # Shared by the course config endpoint and the user endpoints. Different
  # callers include different subsets, so only the always-present core is
  # required and additional properties are permitted.
  OpenApiSpex.schema(%{
    title: "CourseConfiguration",
    description: "Configuration of a course",
    type: :object,
    properties: %{
      courseName: %Schema{type: :string, description: "Course name"},
      courseShortName: %Schema{type: :string, description: "Course module code"},
      viewable: %Schema{type: :boolean, description: "Course viewability"},
      enableGame: %Schema{type: :boolean},
      enableAchievements: %Schema{type: :boolean},
      enableOverallLeaderboard: %Schema{type: :boolean},
      enableContestLeaderboard: %Schema{type: :boolean},
      topLeaderboardDisplay: %Schema{type: :integer},
      topContestLeaderboardDisplay: %Schema{type: :integer},
      enableSourcecast: %Schema{type: :boolean},
      enableStories: %Schema{type: :boolean},
      enableLlmGrading: %Schema{type: :boolean},
      llmModel: %Schema{type: :string, nullable: true},
      llmApiUrl: %Schema{type: :string, nullable: true},
      llmCourseLevelPrompt: %Schema{type: :string, nullable: true},
      pixelbotRoutingPrompt: %Schema{type: :string, nullable: true},
      pixelbotAnswerPrompt: %Schema{type: :string, nullable: true},
      feedbackUrl: %Schema{type: :string, nullable: true},
      sourceChapter: %Schema{type: :integer, description: "Default Source chapter (1-4)"},
      sourceVariant: SourceVariant,
      moduleHelpText: %Schema{type: :string, nullable: true},
      assessmentTypes: %Schema{type: :array, items: %Schema{type: :string}},
      assetsPrefix: %Schema{type: :string, nullable: true, description: "Game assets prefix"}
    },
    required: [:courseName, :courseShortName, :viewable]
  })
end

defmodule CadetWeb.Schemas.CourseConfigResponse do
  @moduledoc false
  require OpenApiSpex
  alias CadetWeb.Schemas.CourseConfiguration

  OpenApiSpex.schema(%{
    title: "CourseConfigResponse",
    description: "Course configuration wrapper",
    type: :object,
    properties: %{config: CourseConfiguration},
    required: [:config]
  })
end

defmodule CadetWeb.Schemas.CreateCourseRequest do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema
  alias CadetWeb.Schemas.SourceVariant

  OpenApiSpex.schema(%{
    title: "CreateCourseRequest",
    description: "Request body for creating a new course",
    type: :object,
    properties: %{
      courseName: %Schema{type: :string, description: "Course name"},
      courseShortName: %Schema{type: :string, description: "Course module code"},
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
      llmModel: %Schema{type: :string},
      llmApiUrl: %Schema{type: :string},
      llmCourseLevelPrompt: %Schema{type: :string},
      sourceChapter: %Schema{type: :integer, description: "Default Source chapter (1-4)"},
      sourceVariant: SourceVariant,
      moduleHelpText: %Schema{type: :string}
    },
    required: [
      :courseName,
      :courseShortName,
      :viewable,
      :enableGame,
      :enableAchievements,
      :enableSourcecast,
      :enableStories,
      :sourceChapter,
      :sourceVariant,
      :moduleHelpText
    ]
  })
end
