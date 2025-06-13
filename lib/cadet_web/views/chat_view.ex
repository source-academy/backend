defmodule CadetWeb.ChatView do
  use CadetWeb, :view

  def render("conversation_init.json", %{conversation_id: id, last_message: last}) do
    %{conversationId: id, response: last}
  end

  def render("conversation.json", %{conversation_id: id, response: response}) do
    %{conversationId: id, response: response}
  end
end
