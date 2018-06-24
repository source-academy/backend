defmodule Cadet.Assessments.Image do
  @moduledoc """
  Image assets used by the missions
  """
  use Cadet, :remote_assets

  @versions [:original]

  def storage_dir(_, _) do
    env = Application.get_env(:cadet, :environment)
    "uploads/#{env}/mission_images"
  end
end
