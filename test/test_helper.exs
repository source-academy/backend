System.put_env("LEADER", "1")

{:ok, _} = Application.ensure_all_started(:ex_machina)

ExUnit.start()
Faker.start()

Ecto.Adapters.SQL.Sandbox.mode(Cadet.Repo, :manual)

defmodule Cadet.TestHelper do
  @doc """
  Removes a preloaded Ecto association.
  """
  def remove_preload(struct, field, cardinality \\ :one) do
    %{
      struct
      | field => %Ecto.Association.NotLoaded{
          __field__: field,
          __owner__: struct.__struct__,
          __cardinality__: cardinality
        }
    }
  end
end
