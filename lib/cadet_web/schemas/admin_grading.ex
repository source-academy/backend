defmodule CadetWeb.Schemas.UpdateGradingRequest do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "UpdateGradingRequest",
    description: "Request body for updating the grading of an answer",
    type: :object,
    properties: %{
      grading: %Schema{
        type: :object,
        description: "Grading fields, e.g. xpAdjustment and comments"
      }
    }
  })
end

defmodule CadetWeb.Schemas.GradingSummaryUser do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "GradingSummaryUser",
    description: "A user (student or team member) shown in a grading summary entry",
    type: :object,
    properties: %{
      id: %Schema{type: :integer},
      name: %Schema{type: :string},
      username: %Schema{type: :string},
      groupName: %Schema{type: :string, nullable: true},
      groupLeaderId: %Schema{type: :integer, nullable: true}
    },
    required: [:id]
  })
end

defmodule CadetWeb.Schemas.GradingSummaryTeam do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema
  alias CadetWeb.Schemas.GradingSummaryUser

  OpenApiSpex.schema(%{
    title: "GradingSummaryTeam",
    description: "The team that made a submission",
    type: :object,
    properties: %{
      id: %Schema{type: :integer},
      # Note: emitted as snake_case by the view.
      team_members: %Schema{type: :array, items: GradingSummaryUser}
    },
    required: [:id]
  })
end

defmodule CadetWeb.Schemas.GradingSummaryAssessment do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "GradingSummaryAssessment",
    description: "Assessment metadata shown in a grading summary entry",
    type: :object,
    properties: %{
      id: %Schema{type: :integer},
      title: %Schema{type: :string},
      assessmentNumber: %Schema{type: :string, nullable: true},
      isManuallyGraded: %Schema{type: :boolean},
      type: %Schema{type: :string, description: "Assessment config type"},
      maxXp: %Schema{type: :integer},
      questionCount: %Schema{type: :integer}
    },
    required: [:id]
  })
end

defmodule CadetWeb.Schemas.GradingSummaryUnsubmitter do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "GradingSummaryUnsubmitter",
    description: "The staff member who unsubmitted the submission",
    type: :object,
    properties: %{
      id: %Schema{type: :integer},
      name: %Schema{type: :string}
    }
  })
end

defmodule CadetWeb.Schemas.GradingSummaryEntry do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  alias CadetWeb.Schemas.{
    GradingSummaryAssessment,
    GradingSummaryTeam,
    GradingSummaryUnsubmitter,
    GradingSummaryUser
  }

  OpenApiSpex.schema(%{
    title: "GradingSummaryEntry",
    description: "A single submission-to-grade row in the grading index",
    type: :object,
    properties: %{
      id: %Schema{type: :integer},
      status: %Schema{type: :string},
      unsubmittedAt: %Schema{type: :string, format: :"date-time", nullable: true},
      xp: %Schema{type: :integer},
      xpAdjustment: %Schema{type: :integer},
      xpBonus: %Schema{type: :integer},
      isGradingPublished: %Schema{type: :boolean},
      gradedCount: %Schema{type: :integer},
      assessment: GradingSummaryAssessment,
      # nil for team submissions (no individual student)
      student: %Schema{nullable: true, allOf: [GradingSummaryUser]},
      # nil for individual (non-team) submissions
      team: %Schema{nullable: true, allOf: [GradingSummaryTeam]},
      unsubmittedBy: %Schema{nullable: true, allOf: [GradingSummaryUnsubmitter]}
    },
    required: [:id]
  })
end

defmodule CadetWeb.Schemas.GradingSummaries do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema
  alias CadetWeb.Schemas.GradingSummaryEntry

  OpenApiSpex.schema(%{
    title: "GradingSummaries",
    description: "Paginated list of submissions to grade",
    type: :object,
    properties: %{
      count: %Schema{type: :integer, description: "Total number of matching submissions"},
      data: %Schema{type: :array, items: GradingSummaryEntry}
    },
    required: [:count, :data]
  })
end

defmodule CadetWeb.Schemas.GradingAssessment do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "GradingAssessment",
    description: "Assessment metadata returned when grading a submission",
    type: :object,
    properties: %{
      id: %Schema{type: :integer},
      title: %Schema{type: :string},
      summaryShort: %Schema{type: :string, nullable: true},
      summaryLong: %Schema{type: :string, nullable: true},
      coverPicture: %Schema{type: :string, nullable: true},
      number: %Schema{type: :string, nullable: true},
      story: %Schema{type: :string, nullable: true},
      reading: %Schema{type: :string, nullable: true}
    },
    required: [:id, :title]
  })
end

defmodule CadetWeb.Schemas.GradingStudent do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "GradingStudent",
    description: "The student who made the submission. May be an empty object for team answers.",
    type: :object,
    properties: %{
      id: %Schema{type: :integer},
      name: %Schema{type: :string},
      username: %Schema{type: :string}
    }
  })
end

defmodule CadetWeb.Schemas.GradingTeamMember do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "GradingTeamMember",
    description: "A member of the team that made the submission",
    type: :object,
    properties: %{
      id: %Schema{type: :integer},
      name: %Schema{type: :string},
      username: %Schema{type: :string}
    }
  })
end

defmodule CadetWeb.Schemas.GradingContestEntry do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "GradingContestEntry",
    description: "A contest entry for a voting question",
    type: :object,
    properties: %{
      submission_id: %Schema{type: :integer},
      answer: %Schema{type: :object, description: "The submitted answer payload"},
      score: %Schema{type: :number, nullable: true}
    }
  })
end

defmodule CadetWeb.Schemas.GradingLeaderboardEntry do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "GradingLeaderboardEntry",
    description: "A leaderboard entry for a voting question",
    type: :object,
    properties: %{
      submission_id: %Schema{type: :integer},
      answer: %Schema{type: :object, description: "The submitted answer payload"},
      student_name: %Schema{type: :string, nullable: true},
      student_username: %Schema{type: :string, nullable: true},
      rank: %Schema{type: :integer, nullable: true},
      final_score: %Schema{type: :number}
    }
  })
end

defmodule CadetWeb.Schemas.GradingQuestion do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  alias CadetWeb.Schemas.{
    AutogradingResult,
    GradingContestEntry,
    GradingLeaderboardEntry,
    Library,
    MCQChoice,
    Testcase
  }

  OpenApiSpex.schema(%{
    title: "GradingQuestion",
    description:
      "A question as seen by a grader, with the student's answer. Fields present depend " <>
        "on the question type (programming, mcq, voting).",
    type: :object,
    properties: %{
      id: %Schema{type: :integer},
      type: %Schema{type: :string, description: "programming, mcq or voting"},
      content: %Schema{type: :string},
      library: Library,
      maxXp: %Schema{type: :integer},
      blocking: %Schema{type: :boolean},
      # programming
      prepend: %Schema{type: :string},
      solutionTemplate: %Schema{type: :string},
      postpend: %Schema{type: :string},
      testcases: %Schema{type: :array, items: Testcase},
      # mcq
      choices: %Schema{type: :array, items: MCQChoice},
      # voting
      contestEntries: %Schema{type: :array, items: GradingContestEntry},
      scoreLeaderboard: %Schema{type: :array, items: GradingLeaderboardEntry},
      popularVoteLeaderboard: %Schema{type: :array, items: GradingLeaderboardEntry},
      # the student's answer: code string (programming), choice index (mcq), or null (voting)
      answer: %Schema{
        nullable: true,
        oneOf: [%Schema{type: :string}, %Schema{type: :integer}]
      },
      autogradingStatus: %Schema{
        type: :string,
        enum: ["none", "processing", "success", "failed"]
      },
      autogradingResults: %Schema{type: :array, items: AutogradingResult}
    },
    required: [:id, :type, :content]
  })
end

defmodule CadetWeb.Schemas.GradingGrade do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema
  alias CadetWeb.Schemas.GraderInfo

  OpenApiSpex.schema(%{
    title: "GradingGrade",
    description: "The grade assigned to an answer",
    type: :object,
    properties: %{
      grader: %Schema{nullable: true, allOf: [GraderInfo]},
      gradedAt: %Schema{type: :string, format: :"date-time", nullable: true},
      xp: %Schema{type: :integer, nullable: true},
      xpAdjustment: %Schema{type: :integer, nullable: true},
      comments: %Schema{type: :string, nullable: true}
    }
  })
end

defmodule CadetWeb.Schemas.GradingAnswer do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema
  alias CadetWeb.Schemas.{GradingGrade, GradingQuestion, GradingStudent, GradingTeamMember}

  OpenApiSpex.schema(%{
    title: "GradingAnswer",
    description: "A single answer within a submission being graded",
    type: :object,
    properties: %{
      id: %Schema{type: :integer},
      # LLM grading prompts; empty unless LLM grading is enabled. Opaque chat messages.
      prompts: %Schema{type: :array, items: %Schema{type: :object}},
      ai_comments: %Schema{
        type: :object,
        nullable: true,
        properties: %{
          response: %Schema{type: :string},
          insertedAt: %Schema{type: :string, format: :"date-time"}
        }
      },
      student: GradingStudent,
      # empty object, null, or a list of team members
      team: %Schema{
        nullable: true,
        oneOf: [
          %Schema{type: :object},
          %Schema{type: :array, items: GradingTeamMember}
        ]
      },
      question: GradingQuestion,
      solution: %Schema{
        type: :string,
        description: "Model solution code, or empty string when not applicable"
      },
      grade: GradingGrade
    },
    required: [:id, :question]
  })
end

defmodule CadetWeb.Schemas.SubmissionGradingInfo do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema
  alias CadetWeb.Schemas.{GradingAnswer, GradingAssessment}

  OpenApiSpex.schema(%{
    title: "SubmissionGradingInfo",
    description: "The answers of a submission to grade, along with assessment metadata",
    type: :object,
    properties: %{
      assessment: GradingAssessment,
      answers: %Schema{type: :array, items: GradingAnswer},
      enable_llm_grading: %Schema{type: :boolean}
    },
    required: [:assessment, :answers, :enable_llm_grading]
  })
end

defmodule CadetWeb.Schemas.GradingGroupSummary do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "GradingGroupSummary",
    description: "Group grading summary table for the course",
    type: :object,
    properties: %{
      cols: %Schema{
        type: :array,
        items: %Schema{type: :string},
        description: "Column headings; dynamic per assessment config type"
      },
      rows: %Schema{
        type: :array,
        # Each row has dynamic keys (groupName, leaderName, plus one submitted<Type>/
        # ungraded<Type> pair per config), so it is modelled as a freeform object.
        items: %Schema{type: :object},
        description: "One row per group; keys correspond to cols"
      }
    },
    required: [:cols, :rows]
  })
end
