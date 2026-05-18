defmodule CadetWeb.Plug.EnsureResourceScope do
  @moduledoc """
  Plug that validates route resource IDs against the current course scope.

  Options:
  - :resource (required) - one of :assessment, :question, :submission, :answer, :team, :course_reg
  - :param (required) - request param name containing the resource ID
  - :assign (optional) - conn.assigns key to store the loaded resource
  """
  import Plug.Conn

  alias Cadet.Accounts.{CourseRegistrations, Teams}
  alias Cadet.Assessments

  @type resource_type :: :assessment | :question | :submission | :answer | :team | :course_reg

  def init(opts), do: opts

  def call(conn, opts) do
    resource = Keyword.fetch!(opts, :resource)
    param = Keyword.fetch!(opts, :param)
    assign_key = Keyword.get(opts, :assign, resource)

    with {:ok, course_id} <- fetch_current_course_id(conn),
         {:ok, resource_id} <- fetch_resource_id(conn.params, param),
         {:ok, record} <- resolve(resource, resource_id, course_id) do
      assign(conn, assign_key, record)
    else
      {:error, :bad_request} ->
        conn
        |> put_status(:bad_request)
        |> send_resp(:bad_request, "Missing or invalid parameter(s)")
        |> halt()

      {:error, :forbidden} ->
        conn
        |> put_status(:forbidden)
        |> send_resp(:forbidden, "Forbidden")
        |> halt()
    end
  end

  defp fetch_current_course_id(conn) do
    case conn.assigns[:course_reg] do
      %{course_id: course_id} -> {:ok, course_id}
      _ -> {:error, :forbidden}
    end
  end

  defp fetch_resource_id(params, param) do
    case Map.get(params, param) do
      nil ->
        {:error, :bad_request}

      id when is_integer(id) and id > 0 ->
        {:ok, id}

      id when is_binary(id) ->
        case Integer.parse(id) do
          {parsed_id, ""} when parsed_id > 0 -> {:ok, parsed_id}
          _ -> {:error, :bad_request}
        end

      _ ->
        {:error, :bad_request}
    end
  end

  defp resolve(:assessment, resource_id, course_id) do
    case Assessments.get_assessment_in_course(resource_id, course_id) do
      nil -> {:error, :forbidden}
      assessment -> {:ok, assessment}
    end
  end

  defp resolve(:question, resource_id, course_id) do
    case Assessments.get_question_in_course(resource_id, course_id) do
      nil -> {:error, :forbidden}
      question -> {:ok, question}
    end
  end

  defp resolve(:submission, resource_id, course_id) do
    case Assessments.get_submission_in_course(resource_id, course_id) do
      nil -> {:error, :forbidden}
      submission -> {:ok, submission}
    end
  end

  defp resolve(:answer, resource_id, course_id) do
    case Assessments.get_answer_in_course(resource_id, course_id) do
      {:ok, answer} -> {:ok, answer}
      {:error, _} -> {:error, :forbidden}
    end
  end

  defp resolve(:team, resource_id, course_id) do
    case Teams.get_team_in_course(resource_id, course_id) do
      nil -> {:error, :forbidden}
      team -> {:ok, team}
    end
  end

  defp resolve(:course_reg, resource_id, course_id) do
    case CourseRegistrations.get_course_reg_in_course(resource_id, course_id) do
      nil -> {:error, :forbidden}
      course_reg -> {:ok, course_reg}
    end
  end
end
