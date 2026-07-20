defmodule CadetWeb.Schemas.XPLeaderboardUser do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "XPLeaderboardUser",
    description: "A single user's entry in the XP leaderboard",
    type: :object,
    properties: %{
      name: %Schema{type: :string, description: "User's full name"},
      username: %Schema{type: :string, description: "User's login name"},
      rank: %Schema{type: :integer, description: "User's rank"},
      user_id: %Schema{type: :integer, description: "User id"},
      total_xp: %Schema{type: :integer, description: "User's total XP"}
    }
  })
end

defmodule CadetWeb.Schemas.XPLeaderboardUsers do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema
  alias CadetWeb.Schemas.XPLeaderboardUser

  OpenApiSpex.schema(%{
    title: "XPLeaderboardUsers",
    description: "XP leaderboard response",
    type: :object,
    properties: %{
      users: %Schema{
        type: :array,
        items: XPLeaderboardUser,
        description: "List of users in the leaderboard"
      },
      total_count: %Schema{
        type: :integer,
        description: "Total number of users in the leaderboard (paginated only)"
      }
    },
    required: [:users]
  })
end
