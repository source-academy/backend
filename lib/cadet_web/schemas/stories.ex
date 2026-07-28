defmodule CadetWeb.Schemas.Story do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "Story",
    description: "A story shown in the Chapter Select screen",
    type: :object,
    properties: %{
      id: %Schema{type: :integer, description: "Story id"},
      title: %Schema{type: :string, description: "Title shown in the Chapter Select screen"},
      filenames: %Schema{
        type: :array,
        items: %Schema{type: :string},
        description: "Filenames of the story's txt files"
      },
      imageUrl: %Schema{
        type: :string,
        nullable: true,
        description: "Path to the image shown in the Chapter Select screen"
      },
      isPublished: %Schema{type: :boolean, description: "Whether the story is published"},
      openAt: %Schema{type: :string, format: :"date-time", description: "The opening date"},
      closeAt: %Schema{type: :string, format: :"date-time", description: "The closing date"},
      courseId: %Schema{type: :integer, description: "Id of the course this story belongs to"}
    },
    required: [:id, :title, :filenames, :isPublished, :openAt, :closeAt, :courseId]
  })
end

defmodule CadetWeb.Schemas.StoryInput do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "StoryInput",
    description: "A story to create, or a set of properties to update",
    type: :object,
    properties: %{
      title: %Schema{type: :string, description: "Title shown in the Chapter Select screen"},
      filenames: %Schema{
        type: :array,
        items: %Schema{type: :string},
        description: "Filenames of the story's txt files"
      },
      imageUrl: %Schema{type: :string, nullable: true, description: "Path to the story's image"},
      openAt: %Schema{type: :string, format: :"date-time", description: "The opening date"},
      closeAt: %Schema{type: :string, format: :"date-time", description: "The closing date"},
      isPublished: %Schema{type: :boolean, description: "Whether the story is published"}
    }
  })
end

defmodule CadetWeb.Schemas.StoryRequest do
  @moduledoc false
  require OpenApiSpex
  alias CadetWeb.Schemas.StoryInput

  OpenApiSpex.schema(%{
    title: "StoryRequest",
    description: "Request body for creating or updating a story",
    type: :object,
    properties: %{story: StoryInput},
    required: [:story]
  })
end
