defmodule Cadet.Updater.Public do
  @moduledoc """
  Represents a guest account in the CS1101S IVLE module. The guest account
  allows us to programmatically access the IVLE module contents, such as
  announcements and files.

  The credentials for the guest account are defined in the `.env` file.
  """

  use GenServer

  alias Cadet.Accounts.IVLE

  require Logger

  @api_key :cadet |> Application.fetch_env!(:updater) |> Keyword.get(:ivle_key)
  @api_url "https://ivle.nus.edu.sg"
  @api_url_login @api_url |> URI.merge("api/login/?apikey=#{@api_key}&url=_") |> URI.to_string()
  @interval :cadet |> Application.fetch_env!(:updater) |> Keyword.get(:interval)
  @username Dotenv.load().values["GUEST_USERNAME"]
  @password Dotenv.load().values["GUEST_PASSWORD"]

  @doc """
  Starts the GenServer.

  WARNING: The GenServer crashes if the API key is invalid, or not provided.
  """
  def start_link do
    GenServer.start_link(__MODULE__, nil)
  end

  @impl true
  @doc """
  Callback for the GenServer. This function calls `schedule_work`, which
  initiates a recursive call every `@interval` milliseconds. This acts as a
  regularly scheduled task (e.g. cronjob).

  `start_link/0` -> `init/1` -> `schedule_work/0` -> `handle_info/2` ->
    `schedule_work/0` -> `handle_info/2` -> ...
  """
  def init(_) do
    Logger.info("Running Cadet.Updater.Public...")
    api_params = get_api_params()
    schedule_work()
    {:ok, api_params}
  end

  @impl true
  @doc """
  Callback for the GenServer. This function receives the message sent by
  `schedule_work/0`, runs and processes `get_announcements/3`, then calls
  `schedule_work/0` recursively.
  """
  def handle_info(:work, api_params) do
    with {:ok, announcements} <- get_announcements(api_params.token, api_params.course_id) do
      Logger.info("Updater fetched #{length(announcements)} announcements from IVLE")
      # TODO: Act on announcements fetched
      schedule_work()
      {:noreply, api_params}
    else
      {:error, :bad_request} ->
        # the token has probably expired---get a new one
        Logger.info("Updater failed fetching announcements. Refreshing token...")
        api_params = get_api_params()
        handle_info(:work, api_params)
    end
  end

  @doc """
  Get the announcements for CS1101S. Returns a list of announcements.

  ## Parameters

    - token: String, the IVLE authentication token
    - course_id: String, the course ID of CS1101S. See `get_course_id/1`

  """
  def get_announcements(token, course_id) do
    IVLE.api_call("Announcements", AuthToken: token, CourseID: course_id)
  end

  @doc """
  Get the authentication token of the guess account, and the CS1101S courseID
  """
  def get_api_params do
    token = get_token()
    course_id = get_course_id(token)
    %{token: token, course_id: course_id}
  end

  @doc """
  Get the course ID of CS1101S. The course ID a required param in the API call
  to get announcements/files from IVLE. The course_id is dynamically fetched
  instead of hard-coded in so that there are less variables to change, if the
  CS1101S module on IVLE changes ID---all that is needed is that the guest
  account is in the CS1101S module.

  ## Parameters

    - token: String, the IVLE authentication token

  """
  def get_course_id(token) do
    {:ok, modules} = IVLE.api_call("Modules", AuthToken: token, CourseID: "CS1101S")

    cs1101s =
      modules["Results"]
      |> Enum.find(fn module ->
        module["CourseCode"] == "CS1101S" and
          module["ID"] != "00000000-0000-0000-0000-000000000000"
      end)

    cs1101s["ID"]
  end

  @doc """
  Get an authentication token for the guest account.

  1. `get_browser_session` is a GET to obtain information representing a
    browser session
  2. Login credentials and information from (1) are sent via POST. IVLE responds
    with a 302.
  3. The location returned in (2) is visited with a GET. Again, IVLE responds
    with a 302. This time, an authentication token is embedded in the location,
    which is extracted with `Regex`.
  """
  def get_token do
    session = get_browser_session()
    http_opts = [hackney: [cookie: session.cookie, follow_redirect: false]]
    form = [userid: @username, password: @password, __VIEWSTATE: session.viewstate]

    location =
      @api_url_login
      |> HTTPoison.post!({:form, form}, %{}, http_opts)
      |> get_redirect_path()

    response =
      @api_url
      |> URI.merge(location)
      |> URI.to_string()
      |> HTTPoison.get!(%{}, http_opts)

    response
    |> get_redirect_path()
    |> URI.parse()
    |> Map.get(:query)
    |> URI.query_decoder()
    |> Enum.into(%{})
    |> Map.get("token")
  end

  # A browser session is identified by the cookie with key ASP.NET_SessionId
  # Additionally, the POST login form requires a field named __VIEWSTATE that is
  # embedded in the html (in an input tag). Therefore, a function
  # `get_browser_session` is defined to return %{:cookie, :viewstate}
  defp get_browser_session do
    response = HTTPoison.get!(@api_url_login)

    viewstate =
      response.body
      |> Floki.find("input#__VIEWSTATE")
      |> Floki.attribute("value")
      |> List.first()

    cookie =
      response.headers
      |> Enum.into(%{})
      |> Map.get("Set-Cookie")

    %{:cookie => cookie, :viewstate => viewstate}
  end

  # Extracts the location of a 302 redirect from a %HTTPoison.Response
  defp get_redirect_path(response) do
    response.headers
    |> Enum.into(%{})
    |> Map.get("Location")
  end

  defp schedule_work do
    Process.send_after(self(), :work, @interval)
  end
end
