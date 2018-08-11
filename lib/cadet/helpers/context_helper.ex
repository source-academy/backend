defmodule Cadet.ContextHelper do
  @moduledoc """
  Contains utility functions that may be commonly used across the Cadet project.
  """

  alias Cadet.Repo

  def simple_update(queryable, id, opts \\ []) do
    params = opts[:params] || []
    using = opts[:using] || fn x, _ -> x end
    model = Repo.get(queryable, id)

    if model == nil do
      {:error, :not_found}
    else
      changeset = using.(model, params)
      Repo.update(changeset)
    end
  end
end
