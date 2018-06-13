defmodule Cadet.ContextHelper do
  @moduledoc false
  import Ecto.Query
  import Ecto.Changeset

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

  def put_display_order(changeset, collection) do
    if Enum.empty?(collection) do
      change(changeset, %{display_order: 1})
    else
      last = Enum.max_by(collection, & &1.display_order)
      change(changeset, %{display_order: last.display_order + 1})
    end
  end
end
