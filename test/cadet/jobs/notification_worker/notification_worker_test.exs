defmodule Cadet.NotificationWorker.NotificationWorkerTest do
  use ExUnit.Case, async: true
  use Oban.Testing, repo: Cadet.Repo
  use Cadet.DataCase
  use Bamboo.Test

  alias Cadet.Repo
  alias Cadet.Workers.NotificationWorker
  alias Cadet.Notifications.{NotificationType, NotificationConfig}

  setup do
    assessments = Cadet.Test.Seeds.assessments()
    avenger_cr = assessments.course_regs.avenger1_cr

    # setup for assessment submission
    _asssub_ntype = Cadet.Notifications.get_notification_type_by_name!("ASSESSMENT SUBMISSION")
    {_name, data} = Enum.at(assessments.assessments, 0)
    submission = List.first(List.first(data.mcq_answers)).submission

    # setup for avenger backlog
    {:ok, %{data: %{submissions: ungraded_submissions}}} =
      Cadet.Assessments.submissions_by_grader_for_index(avenger_cr, %{
        "group" => "true",
        "isFullyGraded" => "false"
      })

    Repo.update_all(NotificationType, set: [is_enabled: true])
    Repo.update_all(NotificationConfig, set: [is_enabled: true])

    {:ok,
     %{
       avenger_user: avenger_cr.user,
       ungraded_submissions: ungraded_submissions,
       submission_id: submission.id
     }}
  end

  test "avenger backlog test", %{
    avenger_user: avenger_user
  } do
    perform_job(NotificationWorker, %{"notification_type" => "avenger_backlog"})

    avenger_email = avenger_user.email
    assert_delivered_email_matches(%{to: [{_, ^avenger_email}]})
  end

  test "assessment submission test", %{
    avenger_user: avenger_user,
    submission_id: submission_id
  } do
    perform_job(NotificationWorker, %{
      "notification_type" => "assessment_submission",
      submission_id: submission_id
    })

    avenger_email = avenger_user.email
    assert_delivered_email_matches(%{to: [{_, ^avenger_email}]})
  end
end
