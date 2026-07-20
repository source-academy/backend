defmodule CadetWeb.Schemas.GenerateAICommentsResponse do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "GenerateAICommentsResponse",
    description: "AI-generated comments for a submission answer",
    type: :object,
    properties: %{
      comments: %Schema{
        type: :array,
        items: %Schema{type: :string},
        description: "AI-generated comment suggestions"
      }
    },
    required: [:comments]
  })
end

defmodule CadetWeb.Schemas.SaveFinalCommentRequest do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "SaveFinalCommentRequest",
    description: "Request body for saving the final chosen comment",
    type: :object,
    properties: %{comment: %Schema{type: :string, description: "The final comment to save"}},
    required: [:comment]
  })
end

defmodule CadetWeb.Schemas.SaveFinalCommentResponse do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "SaveFinalCommentResponse",
    description: "Result of saving the final comment",
    type: :object,
    properties: %{status: %Schema{type: :string, description: "Status of the operation"}},
    required: [:status]
  })
end
