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
          nusnet_id: "E0" <> Integer.to_string(Enum.random(100_000..999_999)) # Due to unique nusnet id constraint
        }
      end

      def student_factory do
        %User{
          name: Faker.Name.En.name(),
          role: :student,
          nusnet_id: "E0" <> Integer.to_string(Enum.random(100_000..999_999))
        }
      end
    end
  end
end
