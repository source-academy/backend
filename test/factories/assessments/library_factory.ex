defmodule Cadet.Assessments.LibraryFactory do
  @moduledoc """
  Factory for the Library entity
  """

  defmacro __using__(_opts) do
    quote do
      alias Cadet.Assessments.Library.ExternalLibraryName

      def library_factory do
        %{
          chapter: Enum.random(1..20),
          globals: Faker.Lorem.words(Enum.random(5..15)),
          external: build(:external_library)
        }
      end

      def external_library_factory do
        %{
          name: Enum.random(ExternalLibraryName.__enum_map__()),
          exposed_symbols: Faker.Lorem.words(Enum.random(5..15))
        }
      end
    end
  end
end
