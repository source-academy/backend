defmodule Cadet.TestEntityHelper do
  @moduledoc """
  Contains entity macros used in tests.
  """

  defmacro achievement_literal(id) do
    Macro.escape(%{
      title: "Achievement #{id}",
      ability: "Core",
      is_task: false,
      xp: 0,
      variable_xp: false,
      position: id,
      card_tile_url: "http://hello#{id}",
      canvas_url: "http://bye#{id}",
      description: "Test #{id}",
      completion_text: "Done #{id}"
    })
  end

  defmacro achievement_json_literal(id) do
    Macro.escape(%{
      "ability" => "Core",
      "position" => id,
      "title" => "Achievement #{id}",
      "xp" => 0,
      "variableXp" => false,
      "cardBackground" => "http://hello#{id}",
      "isTask" => false,
      "view" => %{
        "coverImage" => "http://bye#{id}",
        "completionText" => "Done #{id}",
        "description" => "Test #{id}"
      }
    })
  end

  defmacro goal_literal(id) do
    Macro.escape(%{
      target_count: id,
      text: "Sample #{id}",
      type: "type_#{id}",
      meta: %{"id" => id}
    })
  end

  defmacro goal_json_literal(id) do
    Macro.escape(%{
      "targetCount" => id,
      "meta" => %{"id" => id},
      "text" => "Sample #{id}",
      "type" => "type_#{id}"
    })
  end
end
