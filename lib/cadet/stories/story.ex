defmodule Cadet.Stories.Story do
  @moduledoc """
  The Story entity stores metadata of a story
  """
  use Cadet, :model
  use Arc.Ecto.Schema

  schema "stories" do
    field(:filename, :string, null: false)
    field(:open_at, :utc_datetime_usec)
    field(:close_at, :utc_datetime_usec)
    field(:is_published, :boolean, default: false)

    timestamps()
  end

  @required_fields ~w(open_at close_at filename)a

end
