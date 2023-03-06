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

    ungraded_submissions =
      Jason.decode!(
        elem(Cadet.Assessments.all_submissions_by_grader_for_index(avenger_cr, true, true), 1)
      )

    Repo.update_all(NotificationType, set: [is_enabled: true])
    Repo.update_all(NotificationConfig, set: [is_enabled: true])

    {:ok, %{avenger_user: avenger_cr.user, ungraded_submissions: ungraded_submissions}}
  end

  test "avenger backlog test", %{
    avenger_user: avenger_user
  } do
    perform_job(NotificationWorker, %{"notification_type" => "avenger_backlog"})
    # ntype = Cadet.Notifications.get_notification_type!(1)

    # email =
    #   Cadet.Email.avenger_backlog_email(
    #     ntype.template_file_name,
    #     avenger_user,
    #     ungraded_submissions
    #   )

    # assert_delivered_email(email)
    avenger_email = avenger_user.email

    assert_delivered_email_matches(%{to: [{_, ^avenger_email}]})
  end
end
