defmodule Cadet.ContextHelper do
  @moduledoc false
  import Ecto.Query
  import Ecto.Changeset

  alias Cadet.Repo

  def simple_update(queryable, id, opts \\ []) do
    params = opts[:params] || []
<<<<<<< HEAD
    using = opts[:using] || fn (x, _) -> x end
    model = Repo.get(queryable, id)
=======
    using = opts[:using] || fn x, _ -> x end
    model = Repo.get(queryable, id)

>>>>>>> d08d50a55138354557a30d45d5423d8531f5c5b1
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
<<<<<<< HEAD
      last = Enum.max_by(collection, &(&1.display_order))
      change(changeset, %{display_order: last.display_order + 1 })
=======
      last = Enum.max_by(collection, & &1.display_order)
      change(changeset, %{display_order: last.display_order + 1})
>>>>>>> d08d50a55138354557a30d45d5423d8531f5c5b1
    end
  end

  def update_display_order(queryable, id, offset) do
    model = Repo.get(queryable, id)
<<<<<<< HEAD
    Repo.transaction fn ->
      next_display_order = model.display_order + offset
      next_model =
        Repo.one(
          from u in queryable,
          where: u.display_order == ^next_display_order)
      if next_model != nil do
        Repo.update!(change(model, %{
          display_order: model.display_order + offset
        }))
        Repo.update!(change(next_model, %{
          display_order: model.display_order
        }))
      end
    end
  end

  def toggle_field(queryable, id, field) do
    model = Repo.get(queryable, id)
    new_value = !Map.get(model, field)
    changes = Keyword.put([], field, new_value)
    model
    |> change(changes)
    |> Repo.update
=======

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
>>>>>>> d08d50a55138354557a30d45d5423d8531f5c5b1
  end
end
