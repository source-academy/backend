defmodule CadetWeb.Schemas.UserCourse do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "UserCourse",
    description: "A course the user is registered in",
    type: :object,
    properties: %{
      courseId: %Schema{type: :integer},
      courseName: %Schema{type: :string},
      courseShortName: %Schema{type: :string},
      role: %Schema{type: :string, description: "Student, Staff or Admin"},
      viewable: %Schema{type: :boolean}
    },
    required: [:courseId, :courseName, :courseShortName, :role, :viewable]
  })
end

defmodule CadetWeb.Schemas.UserBasicInfo do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema
  alias CadetWeb.Schemas.UserCourse

  OpenApiSpex.schema(%{
    title: "UserBasicInfo",
    description: "Basic information about the user and their courses",
    type: :object,
    properties: %{
      userId: %Schema{type: :integer},
      name: %Schema{type: :string},
      courses: %Schema{type: :array, items: UserCourse}
    },
    required: [:userId, :name, :courses]
  })
end

defmodule CadetWeb.Schemas.UserStory do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "UserStory",
    description: "The story to display to the user",
    type: :object,
    properties: %{
      story: %Schema{type: :string, nullable: true, description: "Name of the story"},
      playStory: %Schema{type: :boolean, description: "Whether the story should be played"}
    }
  })
end

defmodule CadetWeb.Schemas.CourseRegistrationInfo do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema
  alias CadetWeb.Schemas.UserStory

  OpenApiSpex.schema(%{
    title: "CourseRegistrationInfo",
    description: "The user's registration in their latest viewed course",
    type: :object,
    properties: %{
      courseRegId: %Schema{type: :integer},
      courseId: %Schema{type: :integer},
      role: %Schema{type: :string, description: "Student, Staff or Admin"},
      group: %Schema{type: :string, nullable: true, description: "Group name, if any"},
      xp: %Schema{type: :integer, nullable: true},
      maxXp: %Schema{type: :integer, nullable: true},
      story: %Schema{nullable: true, allOf: [UserStory]},
      gameStates: %Schema{type: :object, description: "The user's game save states"},
      agreedToResearch: %Schema{type: :boolean, nullable: true}
    },
    required: [:courseRegId, :courseId, :role]
  })
end

defmodule CadetWeb.Schemas.AssessmentConfiguration do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "AssessmentConfiguration",
    description: "Configuration for a single assessment type",
    type: :object,
    properties: %{
      assessmentConfigId: %Schema{type: :integer},
      type: %Schema{type: :string},
      displayInDashboard: %Schema{type: :boolean},
      isMinigame: %Schema{type: :boolean},
      isManuallyGraded: %Schema{type: :boolean},
      hasVotingFeatures: %Schema{type: :boolean},
      hasTokenCounter: %Schema{type: :boolean},
      earlySubmissionXp: %Schema{type: :integer},
      hoursBeforeEarlyXpDecay: %Schema{type: :integer},
      isGradingAutoPublished: %Schema{type: :boolean},
      isAutosaveEnabled: %Schema{type: :boolean}
    },
    required: [:assessmentConfigId, :type]
  })
end

defmodule CadetWeb.Schemas.LatestViewedInfo do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema
  alias CadetWeb.Schemas.{AssessmentConfiguration, CourseConfiguration, CourseRegistrationInfo}

  OpenApiSpex.schema(%{
    title: "LatestViewedInfo",
    description: "The user's latest viewed course registration and configuration",
    type: :object,
    properties: %{
      courseRegistration: %Schema{nullable: true, allOf: [CourseRegistrationInfo]},
      courseConfiguration: %Schema{nullable: true, allOf: [CourseConfiguration]},
      assessmentConfigurations: %Schema{
        type: :array,
        items: AssessmentConfiguration,
        nullable: true
      }
    }
  })
end

defmodule CadetWeb.Schemas.UserInfoResponse do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema
  alias CadetWeb.Schemas.{AssessmentConfiguration, CourseConfiguration, CourseRegistrationInfo}
  alias CadetWeb.Schemas.UserBasicInfo

  OpenApiSpex.schema(%{
    title: "UserInfoResponse",
    description: "The user, their courses, and their latest viewed course configuration",
    type: :object,
    properties: %{
      user: UserBasicInfo,
      courseRegistration: %Schema{nullable: true, allOf: [CourseRegistrationInfo]},
      courseConfiguration: %Schema{nullable: true, allOf: [CourseConfiguration]},
      assessmentConfigurations: %Schema{
        type: :array,
        items: AssessmentConfiguration,
        nullable: true
      }
    },
    required: [:user]
  })
end

defmodule CadetWeb.Schemas.TotalXP do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "TotalXP",
    description: "A user's total XP across achievements and assessments",
    type: :object,
    properties: %{totalXp: %Schema{type: :integer}},
    required: [:totalXp]
  })
end

defmodule CadetWeb.Schemas.UpdateLatestViewedRequest do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "UpdateLatestViewedRequest",
    description: "Request body for updating the user's latest viewed course",
    type: :object,
    properties: %{courseId: %Schema{type: :integer, description: "New latest viewed course id"}},
    required: [:courseId]
  })
end

defmodule CadetWeb.Schemas.UpdateGameStatesRequest do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "UpdateGameStatesRequest",
    description: "Request body for updating the user's game save states",
    type: :object,
    properties: %{gameStates: %Schema{type: :object, description: "New game save states"}},
    required: [:gameStates]
  })
end

defmodule CadetWeb.Schemas.UpdateResearchAgreementRequest do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "UpdateResearchAgreementRequest",
    description: "Request body for updating the user's research participation agreement",
    type: :object,
    properties: %{agreedToResearch: %Schema{type: :boolean}},
    required: [:agreedToResearch]
  })
end
