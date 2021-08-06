defmodule Cadet.Courses.SourcecastUpload do
  @moduledoc """
  Represents an uploaded file for Sourcecast
  """
  use Arc.Definition
  use Arc.Ecto.Definition

  @extension_whitelist ~w(.wav)
  @versions [:original]

  # coveralls-ignore-start
  def bucket, do: :cadet |> Application.fetch_env!(:uploader) |> Keyword.get(:sourcecasts_bucket)
  # coveralls-ignore-stop

  def storage_dir(_, _) do
    if Cadet.Env.env() == :test do
      "uploads/test/sourcecasts"
    else
      ""
    end
  end

  def validate({file, _}) do
    file_extension = file.file_name |> Path.extname() |> String.downcase()
    Enum.member?(@extension_whitelist, file_extension)
  end
end
