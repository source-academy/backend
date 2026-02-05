defmodule CadetWeb.ChatView do
  use CadetWeb, :view

  def render("conversation_init.json", %{
        conversation_id: id,
        messages: messages,
        max_content_size: size
      }) do
    %{conversationId: id, messages: messages, maxContentSize: size}
  end

  def render("conversation.json", %{conversation_id: id, response: response}) do
    %{conversationId: id, response: response}
  end
end
