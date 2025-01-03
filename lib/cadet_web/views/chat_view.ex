defmodule CadetWeb.ChatView do
  use CadetWeb, :view

  def render("conversation_init.json", %{
        conversation_id: id,
        last_message: last,
        max_content_size: size
      }) do
    %{conversationId: id, response: last, maxContentSize: size}
  end

  def render("conversation.json", %{conversation_id: id, response: response}) do
    %{conversationId: id, response: response}
  end
end
