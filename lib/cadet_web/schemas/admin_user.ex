defmodule CadetWeb.Schemas.AdminUserInfo do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "AdminUserInfo",
    description: "Basic information about a user in the course",
    type: :object,
    properties: %{
      userId: %Schema{type: :integer},
      name: %Schema{type: :string},
      role: %Schema{type: :string, description: "student, staff or admin"},
      group: %Schema{type: :string, nullable: true, description: "Group name, if any"}
    }
  })
end

defmodule CadetWeb.Schemas.UsernameAndRole do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "UsernameAndRole",
    description: "A username, role and (optionally) group to upsert into the course",
    type: :object,
    properties: %{
      username: %Schema{type: :string, description: "The user's username"},
      role: %Schema{type: :string, description: "student, staff or admin"},
      group: %Schema{type: :string, nullable: true, description: "Group name, if any"}
    },
    required: [:username, :role]
  })
end

defmodule CadetWeb.Schemas.UpsertUsersRequest do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema
  alias CadetWeb.Schemas.UsernameAndRole

  OpenApiSpex.schema(%{
    title: "UpsertUsersRequest",
    description: "Request body for adding or updating users and their groups in the course",
    type: :object,
    properties: %{
      users: %Schema{type: :array, items: UsernameAndRole},
      provider: %Schema{type: :string, description: "The authentication provider for these users"}
    },
    required: [:users, :provider]
  })
end

defmodule CadetWeb.Schemas.UpdateRoleRequest do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "UpdateRoleRequest",
    description: "Request body for updating a user's role",
    type: :object,
    properties: %{role: %Schema{type: :string, description: "The new role"}},
    required: [:role]
  })
end
