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

defmodule CadetWeb.Schemas.TeamMemberInput do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "TeamMemberInput",
    description: "A student to place on a team",
    type: :object,
    properties: %{userId: %Schema{type: :integer, description: "The student's user id"}},
    required: [:userId]
  })
end

defmodule CadetWeb.Schemas.CreateTeamPayload do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema
  alias CadetWeb.Schemas.TeamMemberInput

  OpenApiSpex.schema(%{
    title: "CreateTeamPayload",
    description:
      "Team creation details. `student_ids` is a list of teams, each a list of members.",
    type: :object,
    properties: %{
      assessment_id: %Schema{type: :integer, description: "Assessment id"},
      student_ids: %Schema{
        type: :array,
        items: %Schema{type: :array, items: TeamMemberInput},
        description: "List of teams, each a list of members"
      }
    },
    required: [:assessment_id, :student_ids]
  })
end

defmodule CadetWeb.Schemas.CreateTeamRequest do
  @moduledoc false
  require OpenApiSpex
  alias CadetWeb.Schemas.CreateTeamPayload

  OpenApiSpex.schema(%{
    title: "CreateTeamRequest",
    description: "Request body for creating one or more teams",
    type: :object,
    properties: %{team: CreateTeamPayload},
    required: [:team]
  })
end

defmodule CadetWeb.Schemas.UpdateTeamRequest do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema
  alias CadetWeb.Schemas.TeamMemberInput

  OpenApiSpex.schema(%{
    title: "UpdateTeamRequest",
    description: "Request body for updating a team's members",
    type: :object,
    properties: %{
      teamId: %Schema{type: :integer, description: "Team id"},
      assessmentId: %Schema{type: :integer, description: "Assessment id"},
      student_ids: %Schema{
        type: :array,
        items: %Schema{type: :array, items: TeamMemberInput},
        description: "List of teams, each a list of members"
      }
    },
    required: [:teamId, :assessmentId, :student_ids]
  })
end
