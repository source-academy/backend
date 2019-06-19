defmodule Cadet.Course.Upload do
  @moduledoc """
  Represents an uploaded file
  """
  use Arc.Definition
  use Arc.Ecto.Definition

  @extension_whitelist ~w(.wav)
  @versions [:original]

  def storage_dir(_, _) do
    env = Application.get_env(:cadet, :environment)
    "uploads/#{env}/sourcecast"
  end

  def validate({file, _}) do
    file_extension = file.file_name |> Path.extname() |> String.downcase()
    Enum.member?(@extension_whitelist, file_extension)
  end
end
