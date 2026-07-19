defmodule Cadet.Chatbot.LanguageDirectory do
  @moduledoc """
  Caches the Source Academy language directory and identifies SICPy languages.

  A language is considered SICPy only when its directory entry has a textbook
  URL ending in `json_py/`.
  """

  use GenServer

  require Logger

  @default_url "https://source-academy.github.io/language-directory/directory.json"

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec sicpy_language?(String.t()) :: boolean()
  def sicpy_language?(language_id) when is_binary(language_id) do
    GenServer.call(__MODULE__, {:sicpy_language?, language_id})
  end

  def sicpy_language?(_language_id), do: false

  @doc false
  @spec sicpy_language?(String.t(), list(map()) | map()) :: boolean()
  def sicpy_language?(language_id, directory) when is_binary(language_id) do
    directory
    |> directory_by_id()
    |> Map.get(language_id)
    |> sicpy_entry?()
  end

  def sicpy_language?(_language_id, _directory), do: false

  @impl true
  def init(opts) do
    config = Application.get_env(:cadet, :language_directory, [])
    default_fallback = Application.app_dir(:cadet, "priv/language_directory/directory.json")
    fallback_path = Keyword.get(opts, :fallback_path, config[:fallback_path] || default_fallback)
    languages = fallback_path |> load_fallback() |> directory_by_id()

    state = %{
      languages: languages,
      url: Keyword.get(opts, :url, config[:url] || @default_url),
      refresh_on_start:
        Keyword.get(opts, :refresh_on_start, Keyword.get(config, :refresh_on_start, true))
    }

    if state.refresh_on_start do
      {:ok, state, {:continue, :refresh}}
    else
      {:ok, state}
    end
  end

  @impl true
  def handle_continue(:refresh, state) do
    case fetch_directory(state.url) do
      {:ok, languages} ->
        Logger.info("Loaded #{map_size(languages)} languages from the language directory")
        {:noreply, %{state | languages: languages}}

      {:error, reason} ->
        Logger.error(
          "Could not refresh the language directory; using bundled cache: #{inspect(reason)}"
        )

        {:noreply, state}
    end
  end

  @impl true
  def handle_call({:sicpy_language?, language_id}, _from, state) do
    {:reply, state.languages |> Map.get(language_id) |> sicpy_entry?(), state}
  end

  defp fetch_directory(url) do
    with {:ok, %{status_code: 200, body: body}} <-
           HTTPoison.get(url, [], timeout: 5_000, recv_timeout: 5_000),
         {:ok, directory} when is_list(directory) <- Jason.decode(body) do
      {:ok, directory_by_id(directory)}
    else
      {:ok, %{status_code: status}} -> {:error, {:http_status, status}}
      {:ok, _invalid_json} -> {:error, :invalid_directory}
      {:error, reason} -> {:error, reason}
    end
  end

  defp load_fallback(path) do
    with {:ok, body} <- File.read(path),
         {:ok, directory} when is_list(directory) <- Jason.decode(body) do
      directory
    else
      reason ->
        Logger.error("Could not load bundled language directory: #{inspect(reason)}")
        []
    end
  end

  defp directory_by_id(directory) when is_list(directory) do
    Map.new(directory, fn language -> {Map.get(language, "id"), language} end)
  end

  defp directory_by_id(directory) when is_map(directory), do: directory
  defp directory_by_id(_directory), do: %{}

  defp sicpy_entry?(%{"textbook" => %{"url" => url}}) when is_binary(url) do
    String.ends_with?(url, "json_py/")
  end

  defp sicpy_entry?(_language), do: false
end
