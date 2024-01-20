# credo:disable-for-this-file Credo.Check.Consistency.MultiAliasImportRequireUse
defmodule Cadet do
  @moduledoc """
  Cadet keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  use ContextManager

  def model do
    quote do
      use Ecto.Schema

      import Ecto.Changeset
      import Cadet.ModelHelper
      import Cadet.SharedHelper

      @derive Jason.Encoder
    end
  end

  def context do
    quote do
      alias Cadet.Repo

      import Ecto.Changeset
      import Cadet.ContextHelper
      import Cadet.SharedHelper
    end
  end

  def display do
    quote do
      import Cadet.DisplayHelper
    end
  end

  def remote_assets do
    quote do
      use Arc.Definition
      use Arc.Ecto.Definition
    end
  end
end
