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
