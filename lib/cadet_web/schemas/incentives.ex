defmodule CadetWeb.Schemas.AchievementView do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "AchievementView",
    description: "Achievement view properties",
    type: :object,
    properties: %{
      coverImage: %Schema{type: :string, description: "URL of the image for the view"},
      description: %Schema{type: :string, description: "Achievement description"},
      completionText: %Schema{type: :string, description: "Text to show when completed"}
    }
  })
end

defmodule CadetWeb.Schemas.Achievement do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema
  alias CadetWeb.Schemas.AchievementView

  OpenApiSpex.schema(%{
    title: "Achievement",
    description: "An achievement",
    type: :object,
    properties: %{
      uuid: %Schema{type: :string, format: :uuid, description: "Achievement UUID"},
      title: %Schema{type: :string, description: "Achievement title"},
      xp: %Schema{type: :integer, description: "XP earned when the achievement is completed"},
      isVariableXp: %Schema{
        type: :boolean,
        description: "If true, XP awarded depends on the goal progress"
      },
      cardBackground: %Schema{
        type: :string,
        description: "URL of the achievement's background image"
      },
      release: %Schema{
        type: :string,
        nullable: true,
        description: "Open date, in ISO 8601 format"
      },
      deadline: %Schema{
        type: :string,
        nullable: true,
        description: "Close date, in ISO 8601 format"
      },
      isTask: %Schema{type: :boolean, description: "Whether the achievement is a task"},
      position: %Schema{type: :integer, description: "Position of the achievement in the list"},
      view: AchievementView,
      goalUuids: %Schema{
        type: :array,
        items: %Schema{type: :string, format: :uuid},
        description: "Goal UUIDs"
      },
      prerequisiteUuids: %Schema{
        type: :array,
        items: %Schema{type: :string, format: :uuid},
        description: "Prerequisite achievement UUIDs"
      }
    },
    required: [:title, :isTask, :position, :view]
  })
end

defmodule CadetWeb.Schemas.GoalWithProgress do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "GoalWithProgress",
    description: "A goal, including the current user's progress",
    type: :object,
    properties: %{
      uuid: %Schema{type: :string, format: :uuid, description: "Goal UUID"},
      completed: %Schema{type: :boolean, description: "Whether the user has completed the goal"},
      text: %Schema{type: :string, description: "Text shown for the goal"},
      count: %Schema{type: :integer, description: "Counter for the progress of the goal"},
      targetCount: %Schema{
        type: :integer,
        description: "When count reaches this number, the goal is completed"
      },
      type: %Schema{type: :string, description: "Goal type"},
      meta: %Schema{type: :object, description: "Goal satisfaction information"},
      achievementUuids: %Schema{
        type: :array,
        items: %Schema{type: :string, format: :uuid},
        description: "UUIDs of achievements this goal contributes to"
      }
    },
    required: [:uuid, :completed, :count, :targetCount]
  })
end

defmodule CadetWeb.Schemas.GoalProgressInput do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "GoalProgressInput",
    description: "A user's progress for a single goal",
    type: :object,
    properties: %{
      count: %Schema{type: :integer, description: "Counter for the progress of the goal"},
      completed: %Schema{type: :boolean, description: "Whether the user has completed the goal"},
      uuid: %Schema{type: :string, format: :uuid, description: "Goal UUID (ignored; from path)"},
      course_reg_id: %Schema{type: :integer, description: "Course registration id (ignored)"}
    },
    required: [:count, :completed]
  })
end

defmodule CadetWeb.Schemas.UpdateGoalProgressRequest do
  @moduledoc false
  require OpenApiSpex
  alias CadetWeb.Schemas.GoalProgressInput

  OpenApiSpex.schema(%{
    title: "UpdateGoalProgressRequest",
    description: "Request body for updating a user's goal progress",
    type: :object,
    properties: %{
      progress: GoalProgressInput
    },
    required: [:progress]
  })
end

defmodule CadetWeb.Schemas.UpdateAchievementRequest do
  @moduledoc false
  require OpenApiSpex
  alias CadetWeb.Schemas.Achievement

  OpenApiSpex.schema(%{
    title: "UpdateAchievementRequest",
    description: "Request body for inserting or updating a single achievement",
    type: :object,
    properties: %{
      achievement: Achievement
    },
    required: [:achievement]
  })
end

defmodule CadetWeb.Schemas.BulkUpdateAchievementsRequest do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema
  alias CadetWeb.Schemas.Achievement

  OpenApiSpex.schema(%{
    title: "BulkUpdateAchievementsRequest",
    description: "Request body for inserting or updating multiple achievements",
    type: :object,
    properties: %{
      achievements: %Schema{type: :array, items: Achievement}
    },
    required: [:achievements]
  })
end
