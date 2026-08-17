defmodule Cadet.Assessments.LibraryFactory do
  @moduledoc """
  Factory for the Library entity
  """

  defmacro __using__(_opts) do
    quote do
      alias Cadet.Assessments.Library.ExternalLibraryName

      def library_factory do
        %{
          format: :legacy,
          chapter: Enum.random(1..4),
          globals:
            Enum.reduce(
              0..5,
              %{},
              fn _, acc -> Map.put(acc, Faker.Lorem.word(), Faker.Lorem.sentence()) end
            ),
          external: build(:external_library)
        }
      end

      def conductor_library_factory do
        %{
          format: :conductor,
          language: Enum.random(~w(python-3 python-3-11 javascript node-20 ruby-3)),
          evaluator:
            Enum.random(~w(lambda-pyeval-v1 lambda-pyeval-v2 lambda-jseval-v1 lambda-rbeval-v1))
        }
      end

      def external_library_factory do
        %{
          name: Enum.random(~w(none runes curves sounds binarytrees pixnflix)),
          symbols: Faker.Lorem.words(Enum.random(5..15))
        }
      end
    end
  end
end
