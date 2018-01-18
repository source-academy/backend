defmodule Cadet.Course.MaterialTest do
  use Cadet.ChangesetCase, async: true

  alias Cadet.Course.Material

  valid_changesets Material do
    %{name: "Lecture Notes", description: "This is lecture notes"}
    %{name: "File", file: "test/fixtures/upload.txt"}
  end

  invalid_changesets Material do
    %{name: "", description: "some description"}
  end
end
