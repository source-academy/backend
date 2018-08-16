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
            :nusnet_id
            |> sequence(
              &("E" <>
                  (&1
                   |> Integer.to_string()
                   |> String.pad_leading(7, "0")))
            )
        }
      end

      def student_factory do
        %User{
          name: Faker.Name.En.name(),
          role: :student,
          nusnet_id:
            :nusnet_id
            |> sequence(
              &("E" <>
                  (&1
                   |> Integer.to_string()
                   |> String.pad_leading(7, "0")))
            )
        }
      end
    end
  end
end
