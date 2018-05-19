defmodule Cadet.Course.MaterialTest do
  use Cadet.ChangesetCase, async: true

  alias Cadet.Course.Material

  valid_changesets Material do
    %{name: "Lecture Notes", description: "This is lecture notes"}
    %{name: "File", file: build_upload("test/fixtures/upload.txt", "text/plain")}
  end

  invalid_changesets Material do
    %{name: "", description: "some description"}
  end
end
