defmodule Cadet.ModelHelper do
  @moduledoc """
  This module contains helper for the models.
  """

  import Ecto.Changeset

  alias Timex.Timezone

  def convert_date(:invalid, _) do
    :invalid
  end

  def convert_date(params, field) do
    if is_binary(params[field]) && params[field] != "" do
      timezone = Timezone.get("Asia/Singapore", Timex.now())

      date =
        params[field]
        |> String.to_integer()
        |> Timex.from_unix()
        |> Timezone.convert(timezone)

      Map.put(params, field, date)
    else
      params
    end
  end

  @doc """
  Given a changeset for a model that has some `belongs_to` associations, this function will attach multiple ids to the changeset if the models are provided in the parameters.

  example:
  ```
  defmodule MyTest do
    schema "my_test" do
      belongs_to(:bossman, User)
      belongs_to(:item, Box)
    end

    def changeset(my_test, params) do
      # params = %{bossman: %User{}, item: %Box{}}

      my_test
      |> cast(params, [])
      |> add_belongs_to_id_from_model([:bossman, :item], params)
    end
  end
  ```
  """
  def add_belongs_to_id_from_model(changeset, assoc_list, params) when is_list(assoc_list) do
    Enum.reduce(assoc_list, changeset, fn assoc, changeset ->
      add_belongs_to_id_from_model(changeset, assoc, params)
    end)
  end

  @doc """
  Given a changeset for a model that has some `belongs_to` associations, this function will attach only one id to the changeset if the models are provided in the parameters.

  example:
  ```
  defmodule MyTest do
    schema "my_test" do
      belongs_to(:bossman, User)
    end

    def changeset(my_test, params) do
      # params = %{bossman: %User{}}

      my_test
      |> cast(params, [])
      |> add_belongs_to_id_from_model(:bossman, params)
    end
  end
  ```
  """
  def add_belongs_to_id_from_model(changeset, assoc, params) when is_atom(assoc) do
    assoc_id_field = String.to_atom("#{assoc}_id")

    with nil <- get_change(changeset, assoc_id_field),
         model when is_map(model) <- Map.get(params, assoc),
         id <- Map.get(model, :id) do
      change(changeset, %{"#{assoc}_id": id})
    else
      _ -> changeset
    end
  end
end
