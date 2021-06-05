defmodule Cadet.Accounts.CouseRegistraionFactory do
  @moduledoc """
  Factory(ies) for Cadet.Accounts.CourseRegistration entity
  """

  defmacro __using__(_opts) do
    quote do
      alias Cadet.Accounts.{Role, User, CourseRegistration}
      alias Cadet.Courses.{Course, Group}

      def course_registration_factory do
        %CourseRegstration{
          user: build(:user)
          course: build(:course)
          group: build(:group)
          role: role: Enum.random(Role.__enum_map__()),
          game_status: %{}
        }
      end

      # def student_factory do
      #   %User{
      #     name: Faker.Person.En.name(),
      #     role: :student,
      #     username:
      #       sequence(
      #         :nusnet_id,
      #         &"E#{&1 |> Integer.to_string() |> String.pad_leading(7, "0")}"
      #       ),
      #     game_states: %{}
      #   }
      # end
    end
  end
end
