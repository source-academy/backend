defmodule Cadet.Incentives.GoalFactory do
  @moduledoc """
  Factory for the Goal entity
  """

  defmacro __using__(_opts) do
    quote do
      alias Cadet.Incentives.Goal
      alias Ecto.UUID

      def goal_factory do
        %Goal{
          uuid: UUID.generate(),
          text: "Score earned from Curve Introduction mission",
          target_count: Faker.random_between(1, 1000),
          type: "test_type",
          course: insert(:course),
          meta: %{}
        }
      end
    end
  end
end
