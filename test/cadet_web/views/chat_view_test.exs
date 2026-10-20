defmodule CadetWeb.ChatViewTest do
  use ExUnit.Case, async: true

  alias CadetWeb.ChatView

  test "renders the init session contract" do
    messages = [%{role: "assistant", content: "Hello"}]

    assert ChatView.render("conversation_init.json", %{
             conversation_id: 42,
             messages: messages,
             max_content_size: 1000
           }) == %{conversationId: 42, messages: messages, maxContentSize: 1000}
  end

  test "renders the message session contract" do
    assert ChatView.render("conversation.json", %{conversation_id: 42, response: "Hi"}) == %{
             conversationId: 42,
             response: "Hi"
           }
  end
end
