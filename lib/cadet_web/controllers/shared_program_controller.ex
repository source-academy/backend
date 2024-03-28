defmodule CadetWeb.SharedProgramController do
  use CadetWeb, :controller

  alias Cadet.SharedPrograms
  alias Cadet.SharedPrograms.SharedProgram

  action_fallback CadetWeb.FallbackController


  def index(conn, _params) do
    shared_programs = SharedPrograms.list_shared_programs()
    render(conn, :index, shared_programs: shared_programs)
  end

  def create(conn, %{"shared_program" => shared_program_params}) do
    with {:ok, %SharedProgram{uuid: uuid} = shared_program} <- SharedPrograms.create_shared_program(shared_program_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~s"/api/shared_programs/#{shared_program}")
      # |> render(:show, shared_program: shared_program)
      |> render("show.json", %{uuid: uuid})

      # case ping_url_shortener(uuid) do
      #   {:ok, shortened_url} ->
      #     conn
      #     |> put_status(:created)
      #     |> put_resp_header("location", ~s"/api/shared_programs/#{shared_program}")
      #     # |> render(:show, shared_program: shared_program)
      #     |> render("show.json", %{uuid: uuid, shortened_url: shortened_url})
      #   {:error, reason} ->
      #     conn
      #     |> put_status(:internal_server_error)
      #     |> json(%{error: "Failed to shorten URL: #{reason}"})
      # end
    end
  end

  def show(conn, %{"id" => uuid}) do
    shared_program = SharedPrograms.get_shared_program_by_uuid!(uuid)
    render(conn, :show, shared_program: shared_program)
  end

  def update(conn, %{"id" => id, "shared_program" => shared_program_params}) do
    shared_program = SharedPrograms.get_shared_program!(id)

    with {:ok, %SharedProgram{} = shared_program} <- SharedPrograms.update_shared_program(shared_program, shared_program_params) do
      render(conn, :show, shared_program: shared_program)
    end
  end

  def delete(conn, %{"id" => id}) do
    shared_program = SharedPrograms.get_shared_program!(id)

    with {:ok, %SharedProgram{}} <- SharedPrograms.delete_shared_program(shared_program) do
      send_resp(conn, :no_content, "")
    end
  end

  defp ping_url_shortener(uuid) do
    url = "https://localhost:8000/yourls-api.php"

    params = %{
      signature: "5eef899abd",
      action: "shorturl",
      format: "json",
      keyword: uuid,
      url: "http://localhost:8000/playground#uuid=#{uuid}"
    }

    case HTTPoison.post(url, {:form, params}) do
      {:ok, %{status_code: 200, body: body}} ->
        {:ok, body}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}

      other ->
        {:error, "Unexpected response: #{inspect(other)}"}
    end
  end

end
