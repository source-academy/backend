defmodule Cadet.Course.Query do
  @moduledoc """
  Generate queries related to the Course context
  """
  import Ecto.Query

  alias Cadet.Course.{Category, Material}

  def material_folder_files(folder_id) do
    if is_nil(folder_id) do
      Material
      |> where([m], is_nil(m.category_id))
    else
      Material
      |> where([m], m.category_id == ^folder_id)
    end
  end

  def category_folder_files(folder_id) do
    if is_nil(folder_id) do
      Category
      |> where([m], is_nil(m.category_id))
    else
      Category
      |> where([m], m.category_id == ^folder_id)
    end
  end
end
