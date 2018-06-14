defmodule Cadet.Accounts.IvleTest do
  @moduledoc """
  This test module uses pre-recoreded HTTP responses saved by ExVCR. This
  allows testing without actual API calls.

  In the case that you need to change the recorded responses, you will need
  to set the two environment variables IVLE_KEY (used as a module attribute in
  `Cadet.Accounts.IVLE`) and TOKEN (used here). Don't forget to delete the
  cassette files, otherwise ExVCR will not override the cassettes.
  """

  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Cadet.Accounts.Ivle

  @token String.replace(inspect(System.get_env("TOKEN")), ~s("), "")

  setup_all do
    HTTPoison.start()
  end

  describe "Fetch an NUSNET ID" do
    test "Using a valid token" do
      use_cassette "ivle/fetch_nusnet_id#1" do
        {:ok, resp} = Ivle.fetch_nusnet_id(@token)
        assert String.length(resp) > 0
      end
    end

    test "Using an invalid token" do
      use_cassette "ivle/fetch_nusnet_id#2" do
        {:error, resp} = Ivle.fetch_nusnet_id(@token <> "Z")
        assert resp == :bad_request
      end
    end
  end

  describe "Fetch a name" do
    test "Using a valid token" do
      use_cassette "ivle/fetch_name#1" do
        {:ok, resp} = Ivle.fetch_name(@token)
        assert String.length(resp) > 0
      end
    end

    test "Using an invalid token" do
      use_cassette "ivle/fetch_name#2" do
        {:error, resp} = Ivle.fetch_name(@token <> "Z")
        assert resp == :bad_request
      end
    end
  end
end
