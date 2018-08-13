defmodule Cadet.Accounts.UserFactory do
  @moduledoc """
  Factory(ies) for Cadet.Accounts.User entity
  """

  defmacro __using__(_opts) do
    quote do
      alias Cadet.Accounts.{Role, User}

      def user_factory do
        %User{
          name: Faker.Name.En.name(),
          role: Enum.random(Role.__enum_map__()),
          # Due to unique nusnet id constraint
          nusnet_id:
            sequence(:nusnet_id, &("E" <> String.pad_leading(Integer.to_string(&1), 7, "0")))
        }
      end

      def student_factory do
        %User{
          name: Faker.Name.En.name(),
          role: :student,
          nusnet_id:
            sequence(:nusnet_id, &("E" <> String.pad_leading(Integer.to_string(&1), 7, "0")))
        }
      end
    end
  end
end
