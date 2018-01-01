defmodule Cadet do
  @moduledoc """
  Cadet keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  def model do
    quote do
      use Ecto.Schema

      import Ecto.Changeset
    end
  end

  def context do
    quote do
      alias Cadet.Repo

      import Ecto.Changeset
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
