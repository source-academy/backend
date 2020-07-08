defmodule Cadet.Settings do
  @moduledoc """
  The Settings context contains the configured settings for Academy-wide
  options.
  """
  use Cadet, [:context, :display]

  import Ecto.Query

  alias Cadet.Settings.Sublanguage

  def get_sublanguage do
    # Sublanguage table should only contain 1 entry (as seeded).
    # If there are multiple entries, the most recently created entry will be returned.
    {:ok, retrieve_sublanguage() || %Sublanguage{chapter: 1, variant: "default"}}
  end

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
