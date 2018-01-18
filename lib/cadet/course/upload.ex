defmodule Cadet.Course.Upload do
  @moduledoc """
  Represents an uploaded file
  """
  use Arc.Definition
  use Arc.Ecto.Definition

  @versions [:original]

  def storage_dir(_, _) do
    env = Application.get_env(:cadet, :environment)
    "uploads/#{env}/materials"
  end
end
