defmodule Cadet.Course.MaterialFactory do
  @moduledoc """
  Factory for Material entity
  """

  defmacro __using__(_opts) do
    quote do
      alias Cadet.Course.Material

      def material_folder_factory do
        %Material{
          title: Faker.Cat.name(),
          description: Faker.Cat.breed(),
          uploader: build(:user, %{role: :staff})
        }
      end

      def material_file_factory do
        %Material{
          title: Faker.StarWars.character(),
          description: Faker.StarWars.planet(),
          file: build(:upload),
          uploader: build(:user, %{role: :staff})
        }
      end
    end
  end
end
