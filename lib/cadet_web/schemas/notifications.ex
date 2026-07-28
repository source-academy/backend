defmodule CadetWeb.Schemas.NotificationAssessment do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "NotificationAssessment",
    description: "The assessment a notification references",
    type: :object,
    properties: %{
      type: %Schema{type: :string, description: "Assessment config type"},
      title: %Schema{type: :string, description: "Assessment title"}
    }
  })
end

defmodule CadetWeb.Schemas.Notification do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema
  alias CadetWeb.Schemas.NotificationAssessment

  OpenApiSpex.schema(%{
    title: "Notification",
    description: "A single notification for the current user",
    type: :object,
    properties: %{
      id: %Schema{type: :integer, description: "The notification id"},
      type: %Schema{
        type: :string,
        description: "The type of the notification",
        enum: ~w(new submitted unsubmitted unpublished_grading published_grading new_message)
      },
      assessment_id: %Schema{type: :integer, description: "Referenced assessment id"},
      submission_id: %Schema{
        type: :integer,
        nullable: true,
        description: "Referenced submission id (null for student notifications)"
      },
      assessment: NotificationAssessment
    },
    required: [:id, :type, :assessment_id, :submission_id, :assessment]
  })
end

defmodule CadetWeb.Schemas.AcknowledgeNotificationsRequest do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "AcknowledgeNotificationsRequest",
    description: "Request body for acknowledging notifications",
    type: :object,
    properties: %{
      notificationIds: %Schema{
        type: :array,
        items: %Schema{type: :integer},
        description: "The ids of the notifications to acknowledge"
      }
    },
    required: [:notificationIds]
  })
end
