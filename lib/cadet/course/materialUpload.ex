defmodule Cadet.Course.MaterialUpload do
  @moduledoc """
  Represents an uploaded file for Material
  """
  use Arc.Definition
  use Arc.Ecto.Definition

  @extension_whitelist ~w(.doc .docx .jpg .pdf .png .ppt .pptx .txt .xls .xlsx)
  @versions [:original]

  def bucket, do: :cadet |> Application.fetch_env!(:uploader) |> Keyword.get(:materials_bucket)

  def storage_dir(_, _) do
    if Mix.env() != :test do
      ""
    else
      env = Application.get_env(:cadet, :environment)
      "uploads/#{env}/materials"
    end
  end

  def validate({file, _}) do
    file_extension = file.file_name |> Path.extname() |> String.downcase()
    Enum.member?(@extension_whitelist, file_extension)
  end
end
