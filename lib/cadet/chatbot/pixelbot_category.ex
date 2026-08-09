defmodule Cadet.Chatbot.PixelbotCategory do
  @moduledoc """
  A course-scoped grouping of pixelbot documents. The category name doubles as the
  `doc_type` seen by the routing LLM, resolved by join rather than stored on the document.
  """
  use Cadet, :model

  alias Cadet.Courses.Course
  alias Cadet.Chatbot.PixelbotDocument

  @type t :: %__MODULE__{
          course_id: integer(),
          name: String.t()
        }

  schema "pixelbot_categories" do
    field(:name, :string)

    belongs_to(:course, Course)
    has_many(:documents, PixelbotDocument, foreign_key: :category_id)

    timestamps()
  end

  @required_fields ~w(course_id name)a

  def changeset(category, params) do
    category
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> validate_length(:name, min: 1, max: 255)
    |> foreign_key_constraint(:course_id)
    |> unique_constraint([:course_id, :name])
  end
end
