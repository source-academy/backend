defmodule Cadet.Settings do
  @moduledoc """
  Settings context contains the configured settings for Academy-wide
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
    new_sublanguage =
      case retrieve_sublanguage() do
        nil ->
          %Sublanguage{}
          |> Sublanguage.changeset(%{chapter: chapter, variant: variant})
          |> Repo.insert!()

        sublanguage ->
          sublanguage
          |> Sublanguage.changeset(%{chapter: chapter, variant: variant})
          |> Repo.update!()
      end

    {:ok, new_sublanguage}
  end

  defp retrieve_sublanguage do
    Sublanguage |> order_by(desc: :id) |> limit(1) |> Repo.one()
  end
end
