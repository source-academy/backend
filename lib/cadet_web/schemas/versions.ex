defmodule CadetWeb.Schemas.VersionOverview do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "VersionOverview",
    description: "Summary of a saved answer version",
    type: :object,
    properties: %{
      id: %Schema{type: :integer, description: "Version id"},
      name: %Schema{type: :string, nullable: true, description: "Version name, if named"},
      inserted_at: %Schema{type: :string, format: :"date-time"},
      updated_at: %Schema{type: :string, format: :"date-time"}
    },
    required: [:id]
  })
end

defmodule CadetWeb.Schemas.Version do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "Version",
    description: "A saved answer version, including its content",
    type: :object,
    properties: %{
      id: %Schema{type: :integer, description: "Version id"},
      name: %Schema{type: :string, nullable: true, description: "Version name, if named"},
      answer_id: %Schema{type: :integer, description: "Associated answer id"},
      content: %Schema{description: "Answer content (type depends on the question)"},
      inserted_at: %Schema{type: :string, format: :"date-time"},
      updated_at: %Schema{type: :string, format: :"date-time"}
    },
    required: [:id, :answer_id]
  })
end

defmodule CadetWeb.Schemas.SaveVersionRequest do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "SaveVersionRequest",
    description: "Request body for saving an answer as a new version",
    type: :object,
    properties: %{
      content: %Schema{description: "Answer content (type depends on the question)"}
    },
    required: [:content]
  })
end

defmodule CadetWeb.Schemas.NameVersionRequest do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "NameVersionRequest",
    description: "Request body for naming a version",
    type: :object,
    properties: %{name: %Schema{type: :string, description: "New version name"}},
    required: [:name]
  })
end
