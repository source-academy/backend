defmodule Cadet.Assessments.Assessment do
  @moduledoc false
  use Cadet, :model
  use Arc.Ecto.Schema

  alias Cadet.Assessments.Question

  schema "assessments" do
    field :name, :string
    field :is_published, :boolean, default: false
    field :description, :string, default: ""
    field :briefing, :string, default: ""
    field :max_xp, :integer, default: 0
    field :priority, :integer, default: 0
    has_one :mission, Mission
    timestamps()
  end

  @required_fields ~w(name max_xp)a
  @optional_fields ~w(description briefing is_published priority)a

  def changeset(assessment, params) do
    assessment
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_number(:max_xp, greater_than_or_equal_to: 0)
  end

end
