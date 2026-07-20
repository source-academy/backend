defmodule CadetWeb.Schemas.MCQChoice do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "MCQChoice",
    type: :object,
    properties: %{
      content: %Schema{type: :string, description: "The choice content"},
      hint: %Schema{type: :string, nullable: true, description: "The hint"}
    }
  })
end

defmodule CadetWeb.Schemas.ExternalLibrary do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "ExternalLibrary",
    type: :object,
    properties: %{
      name: %Schema{type: :string, description: "Name of the external library"},
      symbols: %Schema{type: :array, items: %Schema{type: :string}}
    }
  })
end

defmodule CadetWeb.Schemas.Library do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema
  alias CadetWeb.Schemas.ExternalLibrary

  OpenApiSpex.schema(%{
    title: "Library",
    description: "Discriminated library union keyed on `format` (legacy or conductor).",
    type: :object,
    properties: %{
      format: %Schema{type: :string, enum: ["legacy", "conductor"]},
      chapter: %Schema{type: :integer, description: "Source chapter (legacy only)"},
      variant: %Schema{type: :string, description: "Source variant (legacy only)"},
      execTimeMs: %Schema{type: :integer, description: "Execution time in ms (legacy only)"},
      globals: %Schema{type: :array, items: %Schema{type: :string}},
      external: ExternalLibrary,
      languageOptions: %Schema{type: :object, description: "Language options (legacy only)"},
      language: %Schema{type: :string, description: "Conductor language (conductor only)"},
      evaluator: %Schema{type: :string, description: "Conductor evaluator (conductor only)"}
    }
  })
end

defmodule CadetWeb.Schemas.Testcase do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "Testcase",
    type: :object,
    properties: %{
      answer: %Schema{type: :string},
      score: %Schema{type: :integer},
      program: %Schema{type: :string},
      type: %Schema{type: :string, enum: ["public", "opaque", "secret"]}
    }
  })
end

defmodule CadetWeb.Schemas.AutogradingResult do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "AutogradingResult",
    type: :object,
    properties: %{
      resultType: %Schema{type: :string, enum: ["pass", "fail", "error"]},
      expected: %Schema{type: :string},
      actual: %Schema{type: :string}
    }
  })
end

defmodule CadetWeb.Schemas.GraderInfo do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "GraderInfo",
    description: "Information about the grader of an answer",
    type: :object,
    properties: %{
      name: %Schema{type: :string},
      id: %Schema{type: :integer}
    }
  })
end

defmodule CadetWeb.Schemas.Question do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema
  alias CadetWeb.Schemas.{AutogradingResult, GraderInfo, Library, MCQChoice, Testcase}

  OpenApiSpex.schema(%{
    title: "Question",
    type: :object,
    properties: %{
      id: %Schema{type: :integer},
      type: %Schema{type: :string, description: "mcq or programming"},
      content: %Schema{type: :string},
      choices: %Schema{type: :array, items: MCQChoice, description: "MCQ choices (mcq only)"},
      solution: %Schema{type: :integer, nullable: true},
      answer: %Schema{
        nullable: true,
        oneOf: [%Schema{type: :string}, %Schema{type: :integer}],
        description: "Previous answer (type depends on the question)"
      },
      library: Library,
      prepend: %Schema{type: :string},
      solutionTemplate: %Schema{type: :string},
      postpend: %Schema{type: :string},
      testcases: %Schema{type: :array, items: Testcase},
      grader: GraderInfo,
      gradedAt: %Schema{type: :string, format: :"date-time", nullable: true},
      xp: %Schema{type: :integer, description: "Final XP (students only)"},
      grade: %Schema{type: :integer, description: "Final grade (students only)"},
      comments: %Schema{type: :string, nullable: true},
      maxGrade: %Schema{type: :integer},
      maxXp: %Schema{type: :integer},
      autogradingStatus: %Schema{
        type: :string,
        enum: ["none", "processing", "success", "failed"]
      },
      autogradingResults: %Schema{type: :array, items: AutogradingResult}
    },
    required: [:id, :type, :content]
  })
end

defmodule CadetWeb.Schemas.AssessmentOverview do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "AssessmentOverview",
    type: :object,
    properties: %{
      id: %Schema{type: :integer},
      title: %Schema{type: :string},
      config: %Schema{type: :string, description: "Assessment config type"},
      shortSummary: %Schema{type: :string},
      number: %Schema{type: :string},
      story: %Schema{type: :string, nullable: true},
      reading: %Schema{type: :string, nullable: true},
      openAt: %Schema{type: :string, format: :"date-time"},
      closeAt: %Schema{type: :string, format: :"date-time"},
      status: %Schema{
        type: :string,
        enum: ["not_attempted", "attempting", "attempted", "submitted"]
      },
      hasTokenCounter: %Schema{type: :boolean, nullable: true},
      maxXp: %Schema{type: :integer},
      xp: %Schema{type: :integer},
      coverImage: %Schema{type: :string},
      private: %Schema{type: :boolean},
      isPublished: %Schema{type: :boolean},
      questionCount: %Schema{type: :integer},
      gradedCount: %Schema{type: :integer},
      maxTeamSize: %Schema{type: :integer}
    },
    required: [:id, :title]
  })
end

defmodule CadetWeb.Schemas.Assessment do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema
  alias CadetWeb.Schemas.Question

  OpenApiSpex.schema(%{
    title: "Assessment",
    type: :object,
    properties: %{
      id: %Schema{type: :integer},
      title: %Schema{type: :string},
      config: %Schema{type: :string, description: "Assessment config type"},
      number: %Schema{type: :string},
      story: %Schema{type: :string, nullable: true},
      reading: %Schema{type: :string, nullable: true},
      longSummary: %Schema{type: :string},
      hasTokenCounter: %Schema{type: :boolean, nullable: true},
      missionPDF: %Schema{type: :string, nullable: true},
      questions: %Schema{type: :array, items: Question}
    },
    required: [:id, :title]
  })
end

defmodule CadetWeb.Schemas.ContestLeaderboardEntry do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "ContestLeaderboardEntry",
    type: :object,
    properties: %{
      student_name: %Schema{type: :string},
      answer: %Schema{type: :string, description: "The code the student submitted"},
      final_score: %Schema{type: :number, description: "The score obtained"}
    }
  })
end

defmodule CadetWeb.Schemas.ContestLeaderboardResponse do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema
  alias CadetWeb.Schemas.ContestLeaderboardEntry

  OpenApiSpex.schema(%{
    title: "ContestLeaderboardResponse",
    type: :object,
    properties: %{leaderboard: %Schema{type: :array, items: ContestLeaderboardEntry}},
    required: [:leaderboard]
  })
end

defmodule CadetWeb.Schemas.UnlockAssessmentRequest do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "UnlockAssessmentRequest",
    type: :object,
    properties: %{password: %Schema{type: :string, description: "Password to unlock"}},
    required: [:password]
  })
end
