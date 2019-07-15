defmodule Cadet.Course.Query do
  @moduledoc """
  Generate queries related to the Course context
  """
  import Ecto.Query

  alias Cadet.Course.{Category, Material}

  def material_folder_files(folder_id) do
    Material
    |> where([m], m.category_id == ^folder_id)
  end

  def category_folder_files(folder_id) do
    Category
    |> where([m], m.category_id == ^folder_id)
  end
end
