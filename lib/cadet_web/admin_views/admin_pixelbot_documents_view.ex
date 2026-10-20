defmodule CadetWeb.AdminPixelbotDocumentsView do
  use CadetWeb, :view

  def render("index.json", %{categories: categories, documents: documents}) do
    %{
      categories: render_many(categories, __MODULE__, "category.json", as: :category),
      documents: render_many(documents, __MODULE__, "document.json", as: :document)
    }
  end

  def render("category.json", %{category: category}) do
    transform_map_for_view(category, %{
      id: :id,
      name: :name
    })
  end

  def render("document.json", %{document: document}) do
    transform_map_for_view(document, %{
      id: :id,
      categoryId: :category_id,
      docKey: :doc_key,
      title: :title,
      description: :description,
      releaseDate: :release_date,
      filename: :filename,
      mediaType: :media_type
    })
  end
end
