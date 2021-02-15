defmodule Cadet.TestEntityHelper do
  @moduledoc """
  Contains entity macros used in tests.
  """

  defmacro achievement_literal(id) do
    Macro.escape(%{
      title: "Achievement #{id}",
      ability: "Core",
      is_task: false,
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
      "cardTileUrl" => "http://hello#{id}",
      "isTask" => false,
      "view" => %{
        "canvasUrl" => "http://bye#{id}",
        "completionText" => "Done #{id}",
        "description" => "Test #{id}"
      }
    })
  end

  defmacro goal_literal(id) do
    Macro.escape(%{
      max_xp: id,
      text: "Sample #{id}",
      type: "type_#{id}",
      meta: %{"id" => id}
    })
  end

  defmacro goal_json_literal(id) do
    Macro.escape(%{
      "maxExp" => id,
      "meta" => %{"id" => id},
      "text" => "Sample #{id}",
      "type" => "type_#{id}"
    })
  end
end
