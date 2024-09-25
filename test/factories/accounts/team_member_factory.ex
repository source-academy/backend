defmodule Cadet.Accounts.TeamMemberFactory do
  @moduledoc """
  Factory(ies) for Cadet.Accounts.TeamMember entity
  """

  defmacro __using__(_opts) do
    quote do
      # alias Cadet.Accounts.{Role, User}
      alias Cadet.Accounts.TeamMember

      def team_member_factory do
        %TeamMember{
          student: build(:course_registration),
          team: build(:team)
        }
      end
    end
  end
end
