defmodule Cadet.Auth.Providers.SamlTest do
  @moduledoc """
  Tests the SAML authentication provider by simulating validated assertions from the SAML IdP.
  """
  use ExUnit.Case, async: false

  alias Cadet.Auth.Providers.SAML

  import Mock

  @config %{
    assertion_extractor: Cadet.Auth.Providers.NusstfAssertionExtractor,
    client_redirect_url: "http://example.com/login/callback"
  }

  @username_field "SamAccountName"
  @username "JohnT"
  @name_field "DisplayName"
  @name "John Tan"
  @token ~s({"name":"John Tan"})

  test_with_mock "success", Samly,
    get_active_assertion: fn _ ->
      %{attributes: %{@username_field => @username, @name_field => @name}}
    end do
    assert {:ok, %{token: @token, username: @username}} = SAML.authorise(@config, %{conn: %{}})

    assert {:ok, @name} == SAML.get_name(@config, @token)
  end

  test_with_mock "Missing SAML assertion", Samly, get_active_assertion: fn _ -> nil end do
    assert {:error, :invalid_credentials, "Missing SAML assertion!"} =
             SAML.authorise(@config, %{conn: %{}})
  end

  test_with_mock "Missing name attribute", Samly,
    get_active_assertion: fn _ ->
      %{attributes: %{@username_field => @username}}
    end do
    assert {:error, :invalid_credentials, "Missing name attribute!"} =
             SAML.authorise(@config, %{conn: %{}})
  end

  test_with_mock "Missing username attribute", Samly,
    get_active_assertion: fn _ ->
      %{attributes: %{@name_field => @name}}
    end do
    assert {:error, :invalid_credentials, "Missing username attribute!"} =
             SAML.authorise(@config, %{conn: %{}})
  end
end
