defmodule Cadet.Course.Upload do
  @moduledoc """
  Represents an uploaded file
  """
  use Arc.Definition
  use Arc.Ecto.Definition
  def __storage, do: Arc.Storage.Local

  @versions [:original]
end
