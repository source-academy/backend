defmodule Cadet.EmailTest do
  use ExUnit.Case
  use Bamboo.Test
  alias Cadet.{Email, Repo, Accounts}
  alias Cadet.Assessments.Submission

  use Cadet.ChangesetCase, entity: Email

  setup do
    Cadet.Test.Seeds.assessments()

    submission =
      Cadet.Assessments.Submission
      |> Repo.all()
      |> Repo.preload([:assessment])

    {:ok,
     %{
       submission: submission |> List.first()
     }}
  end

  test "avenger backlog email" do
    avenger_user = insert(:user, %{email: "test@gmail.com"})
    avenger = insert(:course_registration, %{user: avenger_user, role: :staff})

    {:ok, %{data: %{submissions: ungraded_submissions}}} =
      Cadet.Assessments.submissions_by_grader_for_index(avenger, %{
        "group" => "true",
        "ungradedOnly" => "true"
      })

    email = Email.avenger_backlog_email("avenger_backlog", avenger_user, ungraded_submissions)

    avenger_email = avenger_user.email
    assert email.to == avenger_email
    assert email.subject == "Backlog for #{avenger_user.name}"
  end

  test "assessment submission email", %{
    submission: submission
  } do
    submission
    |> Submission.changeset(%{status: :submitted})
    |> Repo.update()

    student_id = submission.student_id
    course_reg = Repo.get(Accounts.CourseRegistration, submission.student_id)
    student = Accounts.get_user(course_reg.user_id)
    avenger = Accounts.CourseRegistrations.get_avenger_of(student_id).user

    email =
      Email.assessment_submission_email(
        "assessment_submission",
        avenger,
        student,
        submission
      )

    avenger_email = avenger.email
    assert email.to == avenger_email
    assert email.subject == "New submission for #{submission.assessment.title}"
  end
end
