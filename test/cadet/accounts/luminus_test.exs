defmodule Cadet.Accounts.LuminusTest do
  @moduledoc """
  This test module uses pre-recoreded HTTP responses saved by ExVCR. This
  allows testing without actual external LumiNUS API calls.

  In the case that you need to change the recorded responses, you will need
  to set the config variables `luminus_api_key`, `luminus_client_id`,
  `luminus_client_secret` and `luminus_redirect_url` (used as a module attribute
  in `Cadet.Accounts.Luminus`) and environment variable CODE (used here). Don't
  forget to delete the cassette files, otherwise ExVCR will not override the
  cassettes. You can set the CODE environment variable like so,

    CODE=auth_code_goes_here mix test

  Code refers to the authorization code generated via the OAuth Authorization Grant Type.
  More information can be found here
  https://wiki.nus.edu.sg/pages/viewpage.action?pageId=235638755.
  """

  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Cadet.Accounts.Luminus

  @token "CODE" |> System.get_env() |> Luminus.fetch_luminus_token!()

  setup_all do
    HTTPoison.start()
  end

  describe "Do an API call; methods with empty string for invalid token" do
    test "With a valid token" do
      use_cassette "luminus/api_call#1" do
        assert {:ok, resp} = Luminus.api_call("modulev3", token: @token)
        assert %{"data" => _} = resp
      end
    end

    test "With an invalid token" do
      use_cassette "luminus/api_call#2" do
        assert {:error, :bad_request} = Luminus.api_call("modulev3", token: @token <> "Z")
      end
    end
  end

  describe "Fetch details" do
    test "Using a valid token" do
      use_cassette "luminus/fetch_details#1" do
        assert {:ok, nusnet_id, name} = Luminus.fetch_details(@token)
        assert String.length(nusnet_id) > 0
        assert String.length(name) > 0
      end
    end

    test "Using an invalid token" do
      use_cassette "luminus/fetch_details#2" do
        assert {:error, :bad_request} = Luminus.fetch_details(@token <> "Z")
      end
    end
  end

  describe "Fetch a role" do
    test "Using a valid token" do
      use_cassette "luminus/fetch_role#1" do
        assert {:ok, role} = Luminus.fetch_role(@token)
        assert role in [:student, :staff, :admin]
      end
    end

    test "Using an invalid token" do
      use_cassette "luminus/fetch_role#2" do
        assert {:error, :bad_request} = Luminus.fetch_role(@token <> "Z")
      end
    end
  end

  describe "Map access rights to correct role" do
    test "User does not read CS1101S" do
      use_cassette "luminus/fetch_role#3", custom: true do
        assert {:error, :forbidden} = Luminus.fetch_role(@token)
      end
    end

    test "User no longer reads read CS1101S" do
      use_cassette "luminus/fetch_role#4", custom: true do
        assert {:error, :forbidden} = Luminus.fetch_role(@token)
      end
    end

    test "Student role maps to :student" do
      use_cassette "luminus/fetch_role#5", custom: true do
        assert {:ok, :student} = Luminus.fetch_role(@token)
      end
    end

    test "Read Manager role maps to :staff" do
      use_cassette "luminus/fetch_role#6", custom: true do
        assert {:ok, :staff} = Luminus.fetch_role(@token)
      end
    end

    test "Manager role maps to :staff" do
      use_cassette "luminus/fetch_role#7", custom: true do
        assert {:ok, :staff} = Luminus.fetch_role(@token)
      end
    end

    test "Owner/Co-owner role maps to :admin" do
      use_cassette "luminus/fetch_role#8", custom: true do
        assert {:ok, :admin} = Luminus.fetch_role(@token)
      end
    end

    test "Unknown access role" do
      use_cassette "luminus/fetch_role#9", custom: true do
        assert {:error, :bad_request} = Luminus.fetch_role(@token)
      end
    end
  end
end
