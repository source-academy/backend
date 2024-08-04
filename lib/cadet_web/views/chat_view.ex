defmodule CadetWeb.ChatView do
  use CadetWeb, :view

  def render("conversation_init.json", %{conversation_id: id, last_message: last}) do
    %{conversationId: id, response: last}
  end
end
