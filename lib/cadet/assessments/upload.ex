defmodule Cadet.Assessments.Upload do
  @moduledoc """
  Uploaded PDF file for the mission
  """
  use Cadet, :remote_assets

  @versions [:original]

  def storage_dir(_, _) do
    "uploads/#{Cadet.Env.env()}/mission_pdf"
  end
end
