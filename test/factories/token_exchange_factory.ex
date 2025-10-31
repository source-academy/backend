defmodule Cadet.TokenExchangeFactory do
  @moduledoc """
  Factory for TokenExchange entity
  """

  defmacro __using__(_opts) do
    quote do
      alias Cadet.TokenExchange

      def token_exchange_factory do
        user = build(:user)
        code_ttl = 60

        %TokenExchange{
          code: TokenExchange |> generate_code(),
          generated_at: Timex.now(),
          expires_at: Timex.add(Timex.now(), Timex.Duration.from_seconds(code_ttl)),
          user_id: user.id
        }
      end
    end
  end
end