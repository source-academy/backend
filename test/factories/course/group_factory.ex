defmodule Cadet.Course.GroupFactory do
  @moduledoc """
  Factory for Group entity
  """

  defmacro __using__(_opts) do
    quote do
      alias Cadet.Course.Group

      def group_factory do
        %Group{
          name: sequence("group"),
          leader: build(:user, role: :staff)
        }
      end
    end
  end
end
