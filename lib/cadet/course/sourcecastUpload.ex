defmodule Cadet.Course.SourcecastUpload do
  @moduledoc """
  Represents an uploaded file for Sourcecast
  """
  use Arc.Definition
  use Arc.Ecto.Definition

  @extension_whitelist ~w(.wav)
  @versions [:original]

  def bucket, do: :cadet |> Application.fetch_env!(:uploader) |> Keyword.get(:sourcecasts_bucket)

  def storage_dir(_, _) do
    if Mix.env() != :test do
      ""
    else
      env = Application.get_env(:cadet, :environment)
      "uploads/#{env}/sourcecasts"
    end
  end

  def validate({file, _}) do
    file_extension = file.file_name |> Path.extname() |> String.downcase()
    Enum.member?(@extension_whitelist, file_extension)
  end
end
