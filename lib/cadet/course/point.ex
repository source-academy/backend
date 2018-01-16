defmodule Cadet.Course.Point do
  @moduledoc """
  The Points entities are experience points that are given to
  user manually by staff (for instance due to discussion group). 
  """
  use Cadet, :model

  alias Cadet.Accounts.User

  schema "points" do
    field(:reason, :string)
    field(:amount, :integer)

    belongs_to(:gived_by, User)
    belongs_to(:given_to, User)

    timestamps()
  end

  @required_fields ~w(reason amount)a

  def changeset(point, attrs \\ %{}) do
    point
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> validate_number(:amount, greater_than: 0)
    |> foreign_key_constraint(:given_to_id)
    |> foreign_key_constraint(:given_by)
  end
end
