defmodule Cadet.Settings.SublanguageFactory do
  @moduledoc """
  Factory for the Sublanguage entity
  """

  defmacro __using__(_opts) do
    quote do
      alias Cadet.Settings.Sublanguage

      def sublanguage_factory do
        %Sublanguage{
          chapter: 1,
          variant: "default"
        }
      end
    end
  end
end
