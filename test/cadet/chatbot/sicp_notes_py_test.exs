defmodule Cadet.Chatbot.SicpNotesPyTest do
  use ExUnit.Case, async: true

  alias Cadet.Chatbot.SicpNotesPy

  test "loads Python summaries for all five chapters" do
    for chapter <- 1..5 do
      summary = SicpNotesPy.get_summary(Integer.to_string(chapter))

      assert is_binary(summary)
      assert summary =~ "#{chapter}."
      assert summary =~ "Key terms:"
    end
  end

  test "loads section-level Python summaries" do
    assert SicpNotesPy.get_summary("1.1.1") =~ "Expressions"
    assert SicpNotesPy.get_summary("2.5.3") =~ "Symbolic Algebra"
    assert SicpNotesPy.get_summary("3.5.5") =~ "Modularity"
    assert SicpNotesPy.get_summary("4.4.4") =~ "Implementing the Query System"
    assert SicpNotesPy.get_summary("5.5.7") =~ "Interfacing Compiled Code"
  end

  test "returns nil for an unknown section" do
    assert SicpNotesPy.get_summary("9.9.9") == nil
    assert SicpNotesPy.get_summary(nil) == nil
  end

  test "loads index terms case-insensitively" do
    sections = SicpNotesPy.get_sections_for_term("NEWTON'S METHOD")

    assert "1.1.7" in sections
    assert "1.3.4" in sections
    assert SicpNotesPy.get_sections_for_term("not a real index term") == []
  end
end
