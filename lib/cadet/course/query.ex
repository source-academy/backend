defmodule Cadet.Course.Query do
  @moduledoc """
  Generate queries related to the Course context
  """
  import Ecto.Query

  alias Cadet.Course.Material

  def material_folder_files(folder_id) do
    Material
    |> where([m], m.parent_id == ^folder_id)
  end
end
