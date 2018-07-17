defmodule Cadet.Updater.PublicTest do
  @moduledoc """
  This test module uses pre-recoreded HTTP responses saved by ExVCR. This
  allows testing without actual external IVLE API calls.

  In the case that you need to change the recorded responses, you will need
  to set the config variables :ivle_key, GUEST_USERNAME, and GUEST_PASSWORD.
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

  alias Cadet.Updater.Public

  setup_all do
    HTTPoison.start()
  end

  test "Get authentication token" do
    # a custom cassette is used, as body of 302 redirects expose the api key
    use_cassette "updater/get_token#1", custom: true do
      token = Public.get_token()
      assert String.length(token) == 480
    end
  end

  test "Get course id" do
    use_cassette "updater/get_course_id#1", custom: true do
      course_id = Public.get_course_id("T0K3N...")
      assert String.length(course_id) == 36
      refute course_id == "00000000-0000-0000-0000-000000000000"
    end
  end

  test "Get api params" do
    use_cassette "updater/get_api_params#1", custom: true do
      assert %{token: token, course_id: course_id} = Public.get_api_params()
      assert String.length(token) == 480
      assert String.length(course_id) == 36
      refute course_id == "00000000-0000-0000-0000-000000000000"
    end
  end

  describe "Get announcements" do
    test "Valid token" do
      use_cassette "updater/get_announcements#1", custom: true do
        %{token: token, course_id: course_id} = Public.get_api_params()
        assert {:ok, announcements} = Public.get_announcements(token, course_id)
        assert is_list(announcements)
      end
    end

    test "Invalid token" do
      use_cassette "updater/get_announcements#2" do
        assert {:error, :bad_request} = Public.get_announcements("t0k3n", "")
      end
    end
  end

  describe "Start GenServer" do
    test "Using GenServer.start_link/3" do
      use_cassette "updater/start_link#1", custom: true do
        assert {:ok, _} = GenServer.start_link(Public, nil, name: TestPublic)
        assert :ok = GenServer.stop(TestPublic)
      end
    end

    test "Using Public.start_link/1" do
      use_cassette "updater/start_link#2", custom: true do
        assert {:ok, pid} = Public.start_link()
        assert Process.alive?(pid)
        assert GenServer.stop(pid) == :ok
        refute Process.alive?(pid)
      end
    end
  end

  test "GenServer init/1 callback" do
    use_cassette "updater/init#1", custom: true do
      assert {:ok, %{token: token, course_id: course_id}} = Public.init(nil)
      assert String.length(token) == 480
      assert String.length(course_id) == 36
      refute course_id == "00000000-0000-0000-0000-000000000000"
    end
  end

  describe "Send :work to GenServer" do
    test "Valid token" do
      use_cassette "updater/handle_info#1", custom: true do
        api_params = Public.get_api_params()
        assert {:noreply, new_api_params} = Public.handle_info(:work, api_params)
        assert new_api_params == api_params
      end
    end

    test "Invalid token" do
      use_cassette "updater/handle_info#2", custom: true do
        api_params = %{Public.get_api_params() | token: "bad_token"}
        assert {:noreply, new_api_params} = Public.handle_info(:work, api_params)
        assert api_params.course_id == new_api_params.course_id
        assert String.length(new_api_params.token) == 480
      end
    end
  end
end
