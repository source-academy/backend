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
          role: Enum.random(Role.__enum_map__())
        }
      end

      def student_factory do
        %User{
          name: Faker.Name.En.name(),
          role: :student
        }
      end
    end
  end
end
