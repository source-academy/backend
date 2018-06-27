defmodule Cadet.Public.UpdaterTest do
  @moduledoc """
  This test module uses pre-recoreded HTTP responses saved by ExVCR. This
  allows testing without actual external IVLE API calls.

  In the case that you need to change the recorded responses, you will need
  to set the environment variables IVLE_KEY, GUEST_USERNAME, and GUEST_PASSWORD.
  Don't forget to delete the cassette files, otherwise ExVCR will not override
  the cassettes.

  **Make sure that the cassettes do not expose sensitive information, especially
  the GUEST_USER, GUEST_PASSWORD, since those are exposed during HTTP post.**

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

  test "Get course id" do
    use_cassette "updater/get_course_id#1", custom: true do
      course_id = Updater.get_course_id("T0K3N...")
      assert String.length(course_id) == 36
      assert course_id != "00000000-0000-0000-0000-000000000000"
    end
  end

  test "Get announcements" do
    use_cassette "updater/get_announcements#1", custom: true do
      token = Updater.get_token()
      course_id = Updater.get_course_id(token)
      assert {:ok, announcements} = Updater.get_announcements(token, course_id)
      assert is_list(announcements)
    end
  end

  test "Start GenServer" do
    assert {:ok, _} = GenServer.start_link(Updater, %{}, name: TestUpdater)
    assert :ok = GenServer.stop(TestUpdater)
  end

  test "GenServer init/1 callback" do
    use_cassette "updater/init#1", custom: true do
      assert {:ok, %{token: token, course_id: course_id}} = Updater.init(%{})
      assert String.length(token) == 480
      assert String.length(course_id) == 36
      assert course_id != "00000000-0000-0000-0000-000000000000"
    end
  end
end
