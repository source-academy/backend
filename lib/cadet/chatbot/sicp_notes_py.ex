defmodule Cadet.Chatbot.SicpNotesPy do
  @moduledoc """
  Provides the professor-supplied Python SICP section summaries and index terms.

  The source files live in `priv/chatbot_notes_py`. They are parsed at compile time,
  so serving a chat request does not perform file or network I/O.
  """

  @notes_directory Path.expand("../../../priv/chatbot_notes_py", __DIR__)
  @chapters 1..5
  @notes_files Enum.map(@chapters, &Path.join(@notes_directory, "sicpy_notes_chapter#{&1}.ex"))
  @index_files Enum.map(
                 @chapters,
                 &Path.join(@notes_directory, "sicpy_index_terms_chapter#{&1}.json")
               )

  for path <- @notes_files ++ @index_files do
    @external_resource path
  end

  @notes Enum.reduce(@notes_files, %{}, fn path, notes ->
           ast = path |> File.read!() |> Code.string_to_quoted!(file: path)

           {_, chapter_notes} =
             Macro.prewalk(ast, %{}, fn
               {:@, _, [{attribute, _, [summary]}]} = node, summaries
               when is_atom(attribute) and is_binary(summary) ->
                 case Atom.to_string(attribute) do
                   "summary_" <> section ->
                     {node, Map.put(summaries, String.replace(section, "_", "."), summary)}

                   _other_attribute ->
                     {node, summaries}
                 end

               node, summaries ->
                 {node, summaries}
             end)

           Map.merge(notes, chapter_notes)
         end)

  @index_terms Enum.reduce(@index_files, %{}, fn path, terms ->
                 path
                 |> File.read!()
                 |> Jason.decode!()
                 |> Enum.reduce(terms, fn {term, sections}, accumulated_terms ->
                   Map.update(
                     accumulated_terms,
                     String.downcase(term),
                     sections,
                     &Enum.uniq(&1 ++ sections)
                   )
                 end)
               end)

  @spec get_summary(String.t()) :: String.t() | nil
  def get_summary(section) when is_binary(section), do: Map.get(@notes, section)
  def get_summary(_section), do: nil

  @doc "Returns section numbers associated with an exact, case-insensitive index term."
  @spec get_sections_for_term(String.t()) :: [String.t()]
  def get_sections_for_term(term) when is_binary(term) do
    Map.get(@index_terms, String.downcase(term), [])
  end

  def get_sections_for_term(_term), do: []
end
