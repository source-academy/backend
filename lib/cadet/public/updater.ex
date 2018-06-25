defmodule Cadet.Public.Updater do
  @moduledoc """
  Represents a guest account in the CS1101S IVLE module. The guest account
  allows us to programmatically access the IVLE module contents, such as
  announcements and files.

  The credentials for the guest account are defined in the `.env` file.
  """
  @api_key Dotenv.load().values["IVLE_KEY"]
  @api_url "https://ivle.nus.edu.sg"
  @api_url_login URI.to_string(URI.merge(@api_url, "api/login/?apikey=#{@api_key}&url=_"))
  @username Dotenv.load().values["GUEST_USERNAME"]
  @password Dotenv.load().values["GUEST_PASSWORD"]

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

    response = HTTPoison.post!(@api_url_login, {:form, form}, %{}, http_opts)
    location = get_redirect_path(response)

    response = HTTPoison.get!(join(@api_url, location), %{}, http_opts)

    token =
      response
      |> get_redirect_path()
      |> (&Regex.run(~r/(?<=token=).+/, &1)).()
      |> List.first()

    token
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

    {"Set-Cookie", cookie} =
      response.headers
      |> Enum.filter(fn
        {"Set-Cookie", _} -> true
        _ -> false
      end)
      |> List.first()

    %{:cookie => cookie, :viewstate => viewstate}
  end

  # Extracts the location of a 302 redirect from a %HTTPoison.Response
  defp get_redirect_path(response) do
    {"Location", location} =
      response.headers
      |> Enum.filter(fn
        {"Location", _} -> true
        _ -> false
      end)
      |> List.first()

    location
  end

  # Joins two URI components
  defp join(uri1, uri2) do
    URI.to_string(URI.merge(uri1, uri2))
  end
end
