defmodule Cadet.Accounts.CourseRegistrationFactory do
  @moduledoc """
  Factory(ies) for Cadet.Accounts.CourseRegistration entity
  """

  defmacro __using__(_opts) do
    quote do
      alias Cadet.Accounts.{Role, User, CourseRegistration}
      # alias Cadet.Courses.{Course, Group}

      def course_registration_factory do
        %CourseRegistration{
          user: build(:user),
          course: build(:course),
          # :TODO Group factory is currently wrongly configured
          # group: build(:group),
          role: Enum.random(Role.__enum_map__()),
          game_states: %{}
        }
      end
    end
  end
end
