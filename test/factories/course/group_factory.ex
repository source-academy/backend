defmodule Cadet.Course.GroupFactory do
  @moduledoc """
  Factory for Group entity
  """

  defmacro __using__(_opts) do
    quote do
      alias Cadet.Course.Group

      def group_factory do
        %Group{
          name: Faker.Company.name()
        }
      end
    end
  end
end
