defmodule Cadet.Course.PointTest do
  use Cadet.ChangesetCase, async: true

  alias Cadet.Course.Point

  valid_changesets Point do
    %{reason: "DG XP Week 4", amount: 200}
  end

  invalid_changesets Point do
    %{reason: "", amount: 100}
    %{reason: "Some reason", amount: 0}
    %{reason: "Some reason", amount: -100}
  end
end
