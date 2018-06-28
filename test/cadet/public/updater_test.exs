defmodule Cadet.Public.UpdaterTest do
  @moduledoc """
  This test module uses pre-recoreded HTTP responses saved by ExVCR. This
  allows testing without actual external IVLE API calls.

  In the case that you need to change the recorded responses, you will need
  to set the environment variables IVLE_KEY, GUEST_USERNAME, and GUEST_PASSWORD.
  Don't forget to delete the cassette files, otherwise ExVCR will not override
  the cassettes.

  Token refers to the user's authentication token. Please see the IVLE API docs:
  https://wiki.nus.edu.sg/display/ivlelapi/Getting+Started
  To quickly obtain a token, simply supply a dummy url to a login call:
      https://ivle.nus.edu.sg/api/login/?apikey=YOUR_API_KEY&url=http://localhost
  then copy down the token from your browser's address bar.
  """

  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Cadet.Public.Updater

  setup_all do
    HTTPoison.start()
  end

  test "Get authentication token" do
    # a custom cassette is used, as body of 302 redirects expose the api key
    use_cassette "updater/get_token#1", custom: true do
      token = Updater.get_token()
      assert String.length(token) == 480
    end
  end
end
