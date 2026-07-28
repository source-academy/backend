defmodule CadetWeb.Schemas.SubmitAnswerRequest do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "SubmitAnswerRequest",
    description:
      "An answer to a question. For MCQ questions this is the choice id (integer); " <>
        "for programming questions it is the student's code (string).",
    type: :object,
    properties: %{
      answer: %Schema{
        description:
          "The answer. Type depends on the question: a string (programming), " <>
            "an integer choice id (MCQ), or a list of ranked entries (voting)."
      }
    }
  })
end

defmodule CadetWeb.Schemas.CheckLastModifiedRequest do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "CheckLastModifiedRequest",
    description: "Request body for checking whether an answer was modified after a given time",
    type: :object,
    properties: %{
      lastModifiedAt: %Schema{
        type: :string,
        format: :"date-time",
        description: "The client's last-known modification time"
      }
    },
    required: [:lastModifiedAt]
  })
end

defmodule CadetWeb.Schemas.LastModifiedResponse do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "LastModifiedResponse",
    description: "Whether the stored answer is newer than the client's copy",
    type: :object,
    properties: %{
      lastModified: %Schema{type: :boolean, description: "True if the stored answer is newer"}
    },
    required: [:lastModified]
  })
end
