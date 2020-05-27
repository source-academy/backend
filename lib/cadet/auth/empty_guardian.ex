defmodule Cadet.Auth.EmptyGuardian do
  @moduledoc """
  This module just provides an empty Guardian configuration, sufficient
  to use Guardian.Token.Jwt.Verify.verify_claims.
  """

  def config(_a), do: nil

  def config(_a, def), do: def
end
