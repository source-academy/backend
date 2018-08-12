defmodule Cadet.Course.Group do
  @moduledoc """
  The Group entity represent relations between student
  and discussion group leader
  """
  use Cadet, :model

  alias Cadet.Accounts.User

  schema "groups" do
    field(:name, :string)
    belongs_to(:leader, User)
    belongs_to(:mentor, User)
    has_many(:students, User)
  end

  @required_fields ~w()a
  @optional_fields ~w(name)a

  def changeset(group, leader_id, mentor_id, attrs \\ %{}) do
    group
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> change(%{"leader_id": leader_id})
    |> change(%{"mentor_id": mentor_id})
  end
end
