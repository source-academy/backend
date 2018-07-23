defmodule Cadet.Updater.XMLParser do
  @moduledoc """
  Parser for XML files from the cs1101s repository.
  """
  @local_name if Mix.env() != :test, do: "cs1101s", else: "test/local_repo"
  @locations %{mission: "missions", sidequest: "quests", path: "paths", contest: "contests"}

  defmacrop is_non_empty_list(term) do
    quote do: is_list(unquote(term)) and unquote(term) != []
  end

  @spec parse_and_insert(:mission | :sidequest | :path | :contest) ::
          {:ok, nil} | {:error, String.t()}
  def parse_and_insert(type) do
    with {:assessment_type, true} <- {:assessment_type, type in Map.keys(@locations)},
         {:cloned?, {:ok, root}} when is_non_empty_list(root) <- {:cloned?, File.ls(@local_name)},
         {:type, true} <- {:type, @locations[type] in root},
         {:listing, {:ok, listing}} when is_non_empty_list(listing) <-
           {:listing, @local_name |> Path.join(@locations[type]) |> File.ls()},
         {:filter, xml_files} when is_non_empty_list(xml_files) <-
           {:filter, Enum.filter(listing, &String.ends_with?(&1, ".xml"))} do
      {:ok, nil}
    else
      {:assessment_type, false} -> {:error, "XML location of assessment type is not defined."}
      {:cloned?, {:error, _}} -> {:error, "Local copy of repository is either missing or empty."}
      {:type, false} -> {:error, "Directory containing XML is not found."}
      {:listing, {:error, _}} -> {:error, "Directory containing XML is empty."}
      {:filter, _} -> {:error, "No XML file is found."}
    end
  end
end
