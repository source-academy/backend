defmodule Cadet.Chatbot.PixelbotDocumentTest do
  use Cadet.DataCase

  alias Cadet.Chatbot.PixelbotDocument

  # The column is non-null with a "" default, and the description is what the routing LLM reads.
  # The frontend clears the field to nil rather than "", so both key styles are normalized.
  describe "changeset/2 description normalization" do
    test "turns an atom-keyed nil description into an empty string" do
      changeset = PixelbotDocument.changeset(%PixelbotDocument{}, %{description: nil})

      assert get_field(changeset, :description) == ""
    end

    test "turns a string-keyed nil description into an empty string" do
      changeset = PixelbotDocument.changeset(%PixelbotDocument{}, %{"description" => nil})

      assert get_field(changeset, :description) == ""
    end

    test "leaves a real description alone" do
      changeset = PixelbotDocument.changeset(%PixelbotDocument{}, %{description: "Covers lists."})

      assert get_field(changeset, :description) == "Covers lists."
    end

    test "leaves an absent description to the schema default" do
      changeset = PixelbotDocument.changeset(%PixelbotDocument{}, %{title: "L1A"})

      assert get_field(changeset, :description) == ""
    end
  end

  test "changeset/2 requires everything needed to fetch and route the document" do
    changeset = PixelbotDocument.changeset(%PixelbotDocument{}, %{})

    for field <- [:course_id, :category_id, :doc_key, :title, :s3_key, :filename, :media_type] do
      assert "can't be blank" in errors_on(changeset)[field],
             "expected #{field} to be required"
    end
  end
end
