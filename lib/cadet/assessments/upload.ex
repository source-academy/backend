defmodule Cadet.Assessments.Upload do
  @moduledoc """
  Uploaded PDF file for the mission
  """
  use Cadet, :remote_assets

  @versions [:original]

  def storage_dir(_, _) do
    env = Application.get_env(:cadet, :environment)
    "uploads/#{env}/mission_pdf"
  end
end
