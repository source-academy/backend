defmodule Cadet.Auth.Providers.NusstuAssertionExtractor do
  @moduledoc """
  Extracts fields from NUS Student IdP SAML assertions.
  """

  @behaviour Cadet.Auth.Providers.AssertionExtractor

  def get_username(assertion) do
    Map.get(assertion.attributes, "samaccountname")
  end

  def get_name(assertion) do
    first_name = Map.get(assertion.attributes, "givenname")
    last_name = Map.get(assertion.attributes, "surname")
    "#{first_name} #{last_name}"
  end
end
