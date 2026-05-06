defmodule Cadet.Assessments.VersionManager do
  @moduledoc """
  Service layer for version-related domain logic.
  """
  use Cadet, [:context, :display]
  import Ecto.Query

  require Logger

  alias Cadet.Accounts.{CourseRegistration, Team}

  alias Cadet.Assessments.{
    Answer,
    AnswerTypes.ProgrammingAnswer,
    Assessment,
    Question,
    Submission,
    Version
  }

  def get_versions(
        question = %Question{},
        cr = %CourseRegistration{}
      ) do
    case find_team(question.assessment.id, cr.id) do
      {:ok, team} ->
        base_query =
          Version
          |> order_by(desc: :inserted_at)
          |> join(:inner, [v], a in assoc(v, :answer))
          |> join(:inner, [v, a], s in assoc(a, :submission))
          |> where([v, a, s], a.question_id == ^question.id)

        query =
          case team do
            %Team{} ->
              where(base_query, [_v, _a, s], s.team_id == ^team.id)

            nil ->
              where(base_query, [_v, _a, s], s.student_id == ^cr.id)
          end

        {:ok, Repo.all(query)}

      {:error, :team_not_found} ->
        Logger.error("Team not found for question #{question.id} and user #{cr.id}")
        {:error, {:bad_request, "Your existing Team has been deleted!"}}
    end
  end

  def get_version(
        question = %Question{},
        cr = %CourseRegistration{},
        version_id
      ) do
    case find_team(question.assessment.id, cr.id) do
      {:ok, team} ->
        base_query =
          Version
          |> join(:inner, [v], a in assoc(v, :answer))
          |> join(:inner, [v, a], s in assoc(a, :submission))
          |> where([v, a, s], v.id == ^version_id)
          |> where([v, a, s], a.question_id == ^question.id)

        query =
          case team do
            %Team{} ->
              base_query
              |> where([v, a, s], s.team_id == ^team.id)

            nil ->
              base_query
              |> where([v, a, s], s.student_id == ^cr.id)
          end

        case Repo.one(query) do
          nil -> {:error, {:not_found, "Version not found"}}
          version -> {:ok, version}
        end

      {:error, :team_not_found} ->
        Logger.error("Team not found for question #{question.id} and user #{cr.id}")
        {:error, {:bad_request, "Your existing Team has been deleted!"}}
    end
  end

  def save_version(
        question = %Question{},
        cr = %CourseRegistration{id: cr_id},
        raw_content
      ) do
    if question.type != :programming do
      {:error, {:bad_request, "Can only save version for programming questions"}}
    else
      result =
        Repo.transaction(fn ->
          with {:ok, _team} <- find_team(question.assessment.id, cr_id),
               {:ok, submission} <- find_or_create_submission(cr, question.assessment),
               {:ok, answer} <- find_or_create_answer(question, submission, raw_content),
               {:ok, _version} <- insert_version(question, answer, raw_content) do
            Logger.info("Successfully saved version for answer #{question.id} for user #{cr_id}")
            {:ok, nil}
          else
            {:error, :team_not_found} ->
              Logger.error("Team not found for question #{question.id} and user #{cr_id}")
              Repo.rollback({:bad_request, "Your existing Team has been deleted!"})

            error ->
              Logger.error("Unknown error occurred while saving version: #{inspect(error)}")
              Repo.rollback(error)
          end
        end)

      case result do
        {:ok, success} -> success
        {:error, error} -> {:error, error}
      end
    end
  end

  defp find_or_create_answer(
         question = %Question{},
         submission = %Submission{},
         raw_content
       ) do
    case find_answer(question, submission) do
      {:ok, answer} -> {:ok, answer}
      {:error, _} -> create_new_answer(question, submission, raw_content)
    end
  end

  defp find_answer(question = %Question{}, submission = %Submission{}) do
    answer =
      Answer
      |> where(submission_id: ^submission.id)
      |> where(question_id: ^question.id)
      |> Repo.one()

    if answer do
      {:ok, answer}
    else
      {:error, nil}
    end
  end

  defp create_new_answer(
         question = %Question{},
         submission = %Submission{},
         raw_answer
       ) do
    answer_content = build_answer_content(raw_answer, question.type)

    %Answer{}
    |> Answer.changeset(%{
      answer: answer_content,
      question_id: question.id,
      submission_id: submission.id,
      type: question.type
    })
    |> Repo.insert()
  end

  def insert_version(_question, nil, _raw_content), do: {:ok, :skipped}

  def insert_version(
         question = %Question{},
         answer = %Answer{},
         raw_content
       ) do
    if question.type != :programming do
      {:ok, :skipped}
    else
      content = build_answer_content(raw_content, question.type)

      %Version{}
      |> Version.changeset(%{
        content: content,
        answer_id: answer.id
      })
      |> Repo.insert()
    end
  end

  def name_version(
        question = %Question{},
        cr = %CourseRegistration{},
        version_id,
        name
      ) do
    case find_team(question.assessment.id, cr.id) do
      {:ok, team} ->
        base_query =
          Version
          |> join(:inner, [v], a in assoc(v, :answer))
          |> join(:inner, [v, a], s in assoc(a, :submission))
          |> where([v, a, s], v.id == ^version_id)
          |> where([v, a, s], a.question_id == ^question.id)

        version =
          case team do
            %Team{} ->
              base_query
              |> where([v, a, s], s.team_id == ^team.id)
              |> Repo.one()

            nil ->
              base_query
              |> where([v, a, s], s.student_id == ^cr.id)
              |> Repo.one()
          end

        case version do
          nil ->
            {:error, {:not_found, "Version not found"}}

          version ->
            version
            |> Version.changeset(%{name: name})
            |> Repo.update()
        end

      {:error, :team_not_found} ->
        Logger.error("Team not found for question #{question.id} and user #{cr.id}")
        {:error, {:bad_request, "Your existing Team has been deleted!"}}
    end
  end

  defp find_or_create_submission(%CourseRegistration{} = cr, %Assessment{} = assessment) do
    Cadet.Assessments.find_or_create_submission(cr, assessment)
  end

  defp find_team(assessment_id, cr_id) do
    Cadet.Assessments.find_team(assessment_id, cr_id)
  end

  # TODO: Deduplicate with assessments.ex via helper
  # These are hardcoded to programming question types only

  defp build_answer_content(raw_content, :programming) do
    %{code: raw_content}
  end

  defp build_answer_content(raw_content, _type) do
    raw_content
  end
end
