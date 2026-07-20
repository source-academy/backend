defmodule CadetWeb.Schemas.SourcecastUploader do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "SourcecastUploader",
    description: "The user who uploaded a sourcecast",
    type: :object,
    properties: %{
      id: %Schema{type: :integer, description: "Uploader user id"},
      name: %Schema{type: :string, description: "Uploader name"}
    }
  })
end

defmodule CadetWeb.Schemas.Sourcecast do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema
  alias CadetWeb.Schemas.SourcecastUploader

  OpenApiSpex.schema(%{
    title: "Sourcecast",
    description: "A sourcecast recording",
    type: :object,
    properties: %{
      id: %Schema{type: :integer, description: "Sourcecast id"},
      title: %Schema{type: :string, description: "Title"},
      description: %Schema{type: :string, nullable: true, description: "Description"},
      uid: %Schema{type: :string, nullable: true, description: "Unique identifier"},
      playbackData: %Schema{type: :string, description: "Playback data (JSON-encoded)"},
      url: %Schema{type: :string, nullable: true, description: "URL of the audio file"},
      audio: %Schema{
        type: :object,
        nullable: true,
        description: "Audio attachment (Waffle) metadata"
      },
      inserted_at: %Schema{type: :string, format: :"date-time", description: "Creation time"},
      updated_at: %Schema{type: :string, format: :"date-time", description: "Last update time"},
      courseId: %Schema{
        type: :integer,
        nullable: true,
        description: "Id of the course this sourcecast belongs to"
      },
      uploader: SourcecastUploader
    },
    required: [:id, :title, :playbackData]
  })
end

defmodule CadetWeb.Schemas.SourcecastInput do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "SourcecastInput",
    description: "A sourcecast to upload (sent as multipart/form-data)",
    type: :object,
    properties: %{
      title: %Schema{type: :string, description: "Title"},
      description: %Schema{type: :string, description: "Description"},
      uid: %Schema{type: :string, description: "Unique identifier"},
      playbackData: %Schema{type: :string, description: "Playback data (JSON-encoded)"},
      audio: %Schema{type: :string, format: :binary, description: "Audio file"}
    },
    required: [:title, :audio, :playbackData]
  })
end

defmodule CadetWeb.Schemas.CreateSourcecastRequest do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema
  alias CadetWeb.Schemas.SourcecastInput

  OpenApiSpex.schema(%{
    title: "CreateSourcecastRequest",
    description: "Multipart request body for uploading a sourcecast",
    type: :object,
    properties: %{
      sourcecast: SourcecastInput,
      public: %Schema{
        type: :string,
        description: "Uploads as a public sourcecast when present (any value)"
      }
    },
    required: [:sourcecast]
  })
end
