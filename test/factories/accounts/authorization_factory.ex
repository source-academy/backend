defmodule Cadet.Accounts.AuthorizationFactory do
  @moduledoc """
  Factory(ies) for the Authorization entity
  """

  defmacro __using__(_opts) do
    quote do
      alias Cadet.Accounts.Authorization

      def nusnet_id_factory do
        %Authorization{
          provider: :nusnet_id,
          uid: sequence(:nusnet_id, &"E#{&1}"),
          user: build(:user)
        }
      end
    end
  end
end
