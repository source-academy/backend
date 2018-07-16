defmodule Cadet.Assessments.LibraryFactory do
  @moduledoc """
  Factory for the Library entity
  """

  defmacro __using__(_opts) do
    quote do
      alias Cadet.Assessments.Library

      def library_factory do
        %Library{
          chapter: Enum.random(1..20),
          globals: Faker.Lorem.words(Enum.random(1..3)),
          externals: Faker.Lorem.words(Enum.random(1..3)),
          files: (&Faker.File.file_name/0) |> Stream.repeatedly() |> Enum.take(5)
        }
      end
    end
  end
end
