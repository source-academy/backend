defmodule Mix.Tasks.Cadet.Assessments.Import do
  @moduledoc """
  Import assessments from the cs1101 repository using the XML parser.
  """

  @shortdoc "Import assessments from the cs1101 repository."

  use Mix.Task

  require Logger

  import Mix.Ecto

  alias Cadet.Updater.XMLParser
  alias Cadet.Repo

  def run(_args) do
    # Required for Ecto to work properly, from Mix.Ecto
    ensure_started(Repo, [])
    Application.ensure_all_started(:timex)

    Logger.info("Importing assessments...")

    case XMLParser.parse_and_insert(:all) do
      :ok ->
        Logger.info("Successfully updated assessments.")

      {:error, errors} ->
        for {type, reason} <- errors do
          Logger.error("Error processing #{type}: #{reason}")
        end
    end
  end
end
