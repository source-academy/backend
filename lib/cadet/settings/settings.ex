defmodule Cadet.Settings do
  @moduledoc """
  The Settings context contains functions to retrieve and configure Academy-wide
  settings.
  """
  use Cadet, [:context, :display]

  import Ecto.Query

  alias Cadet.Settings.Sublanguage

  @doc """
  Returns the default Source sublanguage of the Playground, from the most recent
  entry in the Sublanguage table (there should only be 1, as seeded).

  If no entries exist, returns Source 1 as the default sublanguage.
  """
  @spec get_sublanguage :: {:ok, %Sublanguage{}}
  def get_sublanguage do
    {:ok, retrieve_sublanguage() || %Sublanguage{chapter: 1, variant: "default"}}
  end

  @doc """
  Updates the most recent entry in the Sublanguage table to the new chapter and
  variant.

  If no entries exist, inserts a new entry in the Sublanguage table with the
  given chapter and variant.
  """
  @spec update_sublanguage(integer(), String.t()) ::
          {:ok, %Sublanguage{}} | {:error, Ecto.Changeset.t()}
  def update_sublanguage(chapter, variant) do
    case retrieve_sublanguage() do
      nil ->
        %Sublanguage{}
        |> Sublanguage.changeset(%{chapter: chapter, variant: variant})
        |> Repo.insert()

      sublanguage ->
        sublanguage
        |> Sublanguage.changeset(%{chapter: chapter, variant: variant})
        |> Repo.update()
    end
  end

  defp retrieve_sublanguage do
    Sublanguage |> order_by(desc: :id) |> limit(1) |> Repo.one()
  end
end
