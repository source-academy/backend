defmodule Cadet.Course.AnnouncementTest do
  use Cadet.ChangesetCase, async: true

  alias Cadet.Course.Announcement

  valid_changesets Announcement do
    %{title: "title", content: "Hello world", published: true}
  end

  invalid_changesets Announcement do
    %{title: "", content: "Some content"}
  end
end
