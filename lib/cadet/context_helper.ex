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

  def update_display_order(queryable, id, offset) do
    model = Repo.get(queryable, id)

    Repo.transaction(fn ->
      next_display_order = model.display_order + offset
      next_model = Repo.one(from(u in queryable, where: u.display_order == ^next_display_order))

      if next_model != nil do
        Repo.update!(
          change(model, %{
            display_order: model.display_order + offset
          })
        )

        Repo.update!(
          change(next_model, %{
            display_order: model.display_order
          })
        )
      end
    end)
  end
end
