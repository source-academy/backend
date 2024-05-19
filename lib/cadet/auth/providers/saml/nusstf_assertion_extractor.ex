defmodule Cadet.Auth.Providers.NusstfAssertionExtractor do
  @moduledoc """
  Extracts fields from NUS Staff IdP SAML assertions.
  """

  @behaviour Cadet.Auth.Providers.AssertionExtractor

  def get_username(assertion) do
    Map.get(assertion.attributes, "SamAccountName")
  end

  def get_name(assertion) do
    Map.get(assertion.attributes, "DisplayName")
  end
end
