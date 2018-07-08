defmodule Cadet.Course.GroupTest do
  use Cadet.ChangesetCase, async: true

  alias Cadet.Course.Group

  valid_changesets Group do
    %{}
  end
end
