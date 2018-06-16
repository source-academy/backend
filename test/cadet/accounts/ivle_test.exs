defmodule Cadet.Accounts.IvleTest do
  @moduledoc """
  This test module uses pre-recoreded HTTP responses saved by ExVCR. This
  allows testing without actual external IVLE API calls.

  In the case that you need to change the recorded responses, you will need
  to set the two environment variables IVLE_KEY (used as a module attribute in
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

  alias Cadet.Accounts.Ivle

  @token if System.get_env("TOKEN"), do: System.get_env("TOKEN"), else: "token"

  setup_all do
    HTTPoison.start()
  end

  describe "Fetch an NUSNET ID" do
    test "Using a valid token" do
      use_cassette "ivle/fetch_nusnet_id#1" do
        assert {:ok, resp} = Ivle.fetch_nusnet_id(@token)
        assert String.length(resp) > 0
      end
    end

    test "Using an invalid token" do
      use_cassette "ivle/fetch_nusnet_id#2" do
        assert {:error, resp} = Ivle.fetch_nusnet_id(@token <> "Z")
        assert resp == :bad_request
      end
    end
  end

  describe "Fetch a name" do
    test "Using a valid token" do
      use_cassette "ivle/fetch_name#1" do
        assert {:ok, resp} = Ivle.fetch_name(@token)
        assert String.length(resp) > 0
      end
    end

    test "Using an invalid token" do
      use_cassette "ivle/fetch_name#2" do
        assert {:error, resp} = Ivle.fetch_name(@token <> "Z")
        assert resp == :bad_request
      end
    end
  end
end
