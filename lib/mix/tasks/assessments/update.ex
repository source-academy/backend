defmodule Mix.Tasks.Cadet.Assessments.Update do
  @moduledoc """
  Update assessments in database from the CS1101S git repository.

  It will first check if the repository is cloned. If it is not, it will clone it.

  Then it will run pull updates on the repository.

  Finally, it will run the XMLParser on it.
  """

  @shortdoc "Update assessments in database from the CS1101S git repository."

  use Mix.Task

  require Logger

  alias Cadet.Updater.{CS1101S, XMLParser}

  def run(args) do
    with {:cloned?, true} <- {:cloned?, CS1101S.repo_cloned?()},
         {:update, {_, 0}} <- {:update, CS1101S.update()},
         {:parse, :ok} <- {:parse, XMLParser.parse_and_insert(:all)} do
      Logger.info("Successfully updated assessments.")
    else
      {:cloned?, false} ->
        CS1101S.clone()
        run(args)

      {:update, _} ->
        Logger.info("Unable to pull updates")

      {:parse, {:error, errors}} ->
        for {type, reason} <- errors do
          Logger.error("Error processing #{type}: #{reason}")
        end
    end
  end
end
