defmodule Cadet.Auth.EmptyGuardian do
  @moduledoc """
  This module just provides an empty Guardian configuration, sufficient
  to use Guardian.Token.Jwt.Verify.verify_claims.
  """

  def config(a), do: config(a, nil)

  def config(:allowed_drift, _def), do: 10_000

  def config(_a, def), do: def
end
