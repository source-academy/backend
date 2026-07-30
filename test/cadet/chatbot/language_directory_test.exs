defmodule Cadet.Chatbot.LanguageDirectoryTest do
  use ExUnit.Case, async: true

  alias Cadet.Chatbot.LanguageDirectory

  @directory [
    %{
      "id" => "sicpy-custom",
      "textbook" => %{"url" => "https://example.test/books/json_py/"}
    },
    %{
      "id" => "source-custom",
      "textbook" => %{"url" => "https://example.test/books/json/"}
    },
    %{"id" => "python-no-textbook"}
  ]

  test "accepts any directory language whose textbook URL ends in json_py/" do
    assert LanguageDirectory.sicpy_language?("sicpy-custom", @directory)
  end

  test "rejects non-SICPy, missing, and unknown languages" do
    refute LanguageDirectory.sicpy_language?("source-custom", @directory)
    refute LanguageDirectory.sicpy_language?("python-no-textbook", @directory)
    refute LanguageDirectory.sicpy_language?("unknown", @directory)
  end

  test "requires the trailing slash in the metadata suffix" do
    directory = [
      %{"id" => "almost", "textbook" => %{"url" => "https://example.test/json_py"}}
    ]

    refute LanguageDirectory.sicpy_language?("almost", directory)
  end

  test "bundled frontend directory recognizes only textbook-backed Python variants" do
    directory =
      "priv/language_directory/directory.json"
      |> File.read!()
      |> Jason.decode!()

    for language_id <- ~w(python1 python2 python3 python4) do
      assert LanguageDirectory.sicpy_language?(language_id, directory)
    end

    refute LanguageDirectory.sicpy_language?("pythonFull", directory)
    refute LanguageDirectory.sicpy_language?("source1", directory)
  end

  describe "semantics_prompt/1" do
    test "describes the restrictions for each Python textbook language" do
      assert LanguageDirectory.semantics_prompt("python1") =~ "Lists, loops, reassignment"
      assert LanguageDirectory.semantics_prompt("python1") =~ "are not allowed"

      assert LanguageDirectory.semantics_prompt("python2") =~
               "linked-list library is available"

      assert LanguageDirectory.semantics_prompt("python3") =~
               "`for` loops are restricted to `range(...)`"

      assert LanguageDirectory.semantics_prompt("python4") =~ "Python §4"
    end

    test "returns no semantic context without a selected supported language" do
      assert LanguageDirectory.semantics_prompt(nil) == ""
      assert LanguageDirectory.semantics_prompt("source1") == ""
    end
  end
end
