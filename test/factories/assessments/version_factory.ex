defmodule Cadet.Assessments.VersionFactory do
  @moduledoc """
  Factory for the Version entity
  """
  defmacro __using__(_opts) do
    quote do
      alias Cadet.Assessments.Version

      def version_factory do
        %Version{
          content: %{"code" => "return true;"},
          answer: build(:answer)
        }
      end
    end
  end
end
