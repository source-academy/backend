defmodule Cadet.Accounts.TeamFactory do
  @moduledoc """
  Factory(ies) for Cadet.Accounts.Team entity
  """

  defmacro __using__(_opts) do
    quote do
      # alias Cadet.Accounts.{Role, User}
      alias Cadet.Accounts.Team

      def team_factory do
        %Team{
          assessment: build(:assessment)
        }
      end
    end
  end
end
