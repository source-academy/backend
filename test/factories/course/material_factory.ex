defmodule Cadet.Course.MaterialFactory do
  @moduledoc """
  Factory for Material entity
  """

  defmacro __using__(_opts) do
    quote do
      alias Cadet.Course.Material

      def material_folder_factory do
        %Material{
          name: Faker.Cat.name(),
          description: Faker.Cat.breed(),
          uploader: build(:user, %{role: :staff})
        }
      end

      def material_file_factory do
        %Material{
          name: Faker.StarWars.character(),
          description: Faker.StarWars.planet(),
          file: build(:upload),
          parent: build(:material_folder),
          uploader: build(:user, %{role: :staff})
        }
      end
    end
  end
end
