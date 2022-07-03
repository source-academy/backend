defmodule Cadet.Accounts.UserFactory do
  @moduledoc """
  Factory(ies) for Cadet.Accounts.User entity
  """

  defmacro __using__(_opts) do
    quote do
      # alias Cadet.Accounts.{Role, User}
      alias Cadet.Accounts.User

      def user_factory do
        %User{
          provider: "test",
          name: Faker.Person.En.name(),
          username:
            sequence(
              :nusnet_id,
              &"E#{&1 |> Integer.to_string() |> String.pad_leading(7, "0")}"
            ),
          latest_viewed_course: build(:course),
          super_admin: false
        }
      end

      def student_factory do
        %User{
          provider: "test",
          name: Faker.Person.En.name(),
          username:
            sequence(
              :nusnet_id,
              &"E#{&1 |> Integer.to_string() |> String.pad_leading(7, "0")}"
            ),
          latest_viewed_course: build(:course)
        }
      end
    end
  end
end
