defmodule Cadet.Accounts.IVLETest do
  @moduledoc """
  This test module uses pre-recoreded HTTP responses saved by ExVCR. This
  allows testing without actual external IVLE API calls.

  In the case that you need to change the recorded responses, you will need
  to set the two config variables `:ivle_key` (used as a module attribute in
  `Cadet.Accounts.IVLE`) and TOKEN (used here). Don't forget to delete the
  cassette files, otherwise ExVCR will not override the cassettes.

  Token refers to the user's authentication token. Please see the IVLE API docs:
  https://wiki.nus.edu.sg/display/ivlelapi/Getting+Started
  To quickly obtain a token, simply supply a dummy url to a login call:
      https://ivle.nus.edu.sg/api/login/?apikey=YOUR_API_KEY&url=http://localhost
  then copy down the token from your browser's address bar.
  """

  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Cadet.Accounts.IVLE

  @token if System.get_env("TOKEN"), do: System.get_env("TOKEN"), else: "token"

  setup_all do
    HTTPoison.start()
  end

  describe "Do an API call; methods with empty string for invalid token" do
    test "With one parameter token" do
      use_cassette "ivle/api_call#1" do
        assert {:ok, resp} = IVLE.api_call("UserName_Get", Token: @token)
        assert String.length(resp) > 0
      end
    end

    test "With two parameters token, course code" do
      use_cassette "ivle/api_call#2" do
        assert {:ok, resp} = IVLE.api_call("Modules", AuthToken: @token, CourseID: "CS1101S")
        assert %{"Results" => _} = resp
      end
    end

    test "With an invalid api key" do
      use_cassette "ivle/api_call#3", custom: true do
        assert {:error, :internal_server_error} = IVLE.api_call("UserName_Get", Token: @token)
      end
    end

    test "With an invalid token" do
      use_cassette "ivle/api_call#4" do
        assert {:error, :bad_request} = IVLE.api_call("UserName_Get", Token: @token <> "Z")
      end
    end
  end

  describe ~s(Do an API call; methods with "Invalid token!" for invalid token) do
    test "With a valid token" do
      use_cassette "ivle/api_call#5" do
        assert {:ok, _} = IVLE.api_call("Announcements", AuthToken: @token, CourseID: "")
      end
    end

    test "With an invalid token" do
      use_cassette "ivle/api_call#6" do
        assert {:error, :bad_request} =
                 IVLE.api_call("Announcements", AuthToken: @token <> "Z", CourseID: "")
      end
    end

    test "With an invalid key" do
      use_cassette "ivle/api_call#7", custom: true do
        assert {:error, :internal_server_error} =
                 IVLE.api_call("Announcements", AuthToken: @token, CourseID: "")
      end
    end
  end

  describe "Fetch an NUSNET ID" do
    test "Using a valid token" do
      use_cassette "ivle/fetch_nusnet_id#1" do
        assert {:ok, resp} = IVLE.fetch_nusnet_id(@token)
        assert String.length(resp) > 0
      end
    end

    test "Using an invalid token" do
      use_cassette "ivle/fetch_nusnet_id#2" do
        assert {:error, resp} = IVLE.fetch_nusnet_id(@token <> "Z")
        assert resp == :bad_request
      end
    end
  end

  describe "Fetch a name" do
    test "Using a valid token" do
      use_cassette "ivle/fetch_name#1" do
        assert {:ok, resp} = IVLE.fetch_name(@token)
        assert String.length(resp) > 0
      end
    end

    test "Using an invalid token" do
      use_cassette "ivle/fetch_name#2" do
        assert {:error, resp} = IVLE.fetch_name(@token <> "Z")
        assert resp == :bad_request
      end
    end
  end

  describe "Fetch a role" do
    test "Using a valid token" do
      use_cassette "ivle/fetch_role#1" do
        assert {:ok, role} = IVLE.fetch_role(@token)
        assert Enum.member?([:student, :staff, :admin], role)
      end
    end

    test "Using an invalid token" do
      use_cassette "ivle/fetch_role#2" do
        assert {:error, :bad_request} = IVLE.fetch_role(@token <> "Z")
      end
    end
  end

  describe "Map permission to correct role" do
    test ~s(Permission "O" maps to :admin) do
      use_cassette "ivle/fetch_role#3", custom: true do
        assert {:ok, :admin} = IVLE.fetch_role(@token)
      end
    end

    test ~s(Permission "F" maps to :admin) do
      use_cassette "ivle/fetch_role#4", custom: true do
        assert {:ok, :admin} = IVLE.fetch_role(@token)
      end
    end

    test ~s(Permission "M" maps to :staff) do
      use_cassette "ivle/fetch_role#5", custom: true do
        assert {:ok, :staff} = IVLE.fetch_role(@token)
      end
    end

    test ~s(Permission "R" maps to :staff) do
      use_cassette "ivle/fetch_role#6", custom: true do
        assert {:ok, :staff} = IVLE.fetch_role(@token)
      end
    end

    test ~s(Permission "S" maps to :student) do
      use_cassette "ivle/fetch_role#7", custom: true do
        assert {:ok, :student} = IVLE.fetch_role(@token)
      end
    end
  end
end
