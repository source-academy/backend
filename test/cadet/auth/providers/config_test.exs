defmodule Cadet.Auth.Providers.ConfigTest do
  use ExUnit.Case, async: true

  alias Cadet.Auth.Providers.Config

  @code "code"
  @token "token"
  @name "Test Name"
  @username "testusername"
  @role :student

  @config [
    %{
      token: @token,
      code: @code,
      name: @name,
      username: @username,
      role: @role
    }
  ]

  describe "authorise" do
    test "successfully" do
      assert {:ok, %{token: @token, username: @username}} =
               Config.authorise(@config, @code, nil, nil)
    end

    test "with wrong code" do
      assert {:error, _, _} = Config.authorise(@config, @code <> "dflajhdfs", nil, nil)
    end
  end

  describe "get name" do
    test "successfully" do
      assert {:ok, @name} = Config.get_name(@config, @token)
    end

    test "with wrong token" do
      assert {:error, _, _} = Config.get_name(@config, @token <> "dflajhdfs")
    end
  end

  describe "get role" do
    test "successfully" do
      assert {:ok, @role} = Config.get_role(@config, @token)
    end

    test "with wrong token" do
      assert {:error, _, _} = Config.get_role(@config, @token <> "dflajhdfs")
    end
  end
end
