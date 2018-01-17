defmodule Cadet.Course.Group do
  @moduledoc """
  The Group entity represent relations between student
  and discussion group leader
  """
  use Cadet, :model

  alias Cadet.Accounts.User

  schema "groups" do
    belongs_to(:leader, User)
    belongs_to(:student, User)
  end

  def changeset(group, attrs \\ %{}) do
    group
    |> cast(attrs, [])
    |> foreign_key_constraint(:leader_id)
    |> foreign_key_constraint(:student_id)
  end
end
