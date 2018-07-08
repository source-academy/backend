defmodule Cadet.Assessments.LibraryTest do
  use Cadet.ChangesetCase, async: true

  alias Cadet.Assessments.Library

  valid_changesets Library do
    %{
      version: 1
    }

    %{
      version: 1,
      globals: ["asd"],
      externals: [],
      fields: []
    }
  end
end
