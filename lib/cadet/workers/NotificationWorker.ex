defmodule Cadet.Workers.NotificationWorker do
  @moduledoc """
  Contain oban workers for sending notifications
  """
  use Oban.Worker, queue: :notifications, max_attempts: 1
  alias Cadet.{Email, Notifications, Mailer}
  alias Cadet.Repo

  defp is_system_enabled(notification_type_id) do
    Notifications.get_notification_type!(notification_type_id).is_enabled
  end

  defp is_course_enabled(notification_type_id, course_id, assessment_config_id) do
    notification_config =
      Notifications.get_notification_config!(
        notification_type_id,
        course_id,
        assessment_config_id
      )

    if is_nil(notification_config) do
      false
    else
      notification_config.is_enabled
    end
  end

  defp is_user_enabled(notification_type_id, course_reg_id) do
    pref = Notifications.get_notification_preference(notification_type_id, course_reg_id)

    if is_nil(pref) do
      true
    else
      pref.is_enabled
    end
  end

  # Returns true if user preference matches the job's time option.
  # If user has made no preference, the default time option is used instead
  def is_user_time_option_matched(
        notification_type_id,
        assessment_config_id,
        course_reg_id,
        time_option_minutes
      ) do
    pref = Notifications.get_notification_preference(notification_type_id, course_reg_id)

    if is_nil(pref) or is_nil(pref.time_option) do
      Notifications.get_default_time_option_for_assessment!(
        assessment_config_id,
        notification_type_id
      ).minutes == time_option_minutes
    else
      pref.time_option.minutes == time_option_minutes
    end
  end

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{"notification_type" => notification_type} = _args
      })
      when notification_type == "avenger_backlog" do
    ungraded_threshold = 5

    ntype = Cadet.Notifications.get_notification_type_by_name!("AVENGER BACKLOG")
    notification_type_id = ntype.id

    if is_system_enabled(notification_type_id) do
      for course_id <- Cadet.Courses.get_all_course_ids() do
        if is_course_enabled(notification_type_id, course_id, nil) do
          avengers_crs = Cadet.Accounts.CourseRegistrations.get_staffs(course_id)

          for avenger_cr <- avengers_crs do
            avenger = Cadet.Accounts.get_user(avenger_cr.user_id)

            {:ok, %{data: %{submissions: ungraded_submissions}}} =
              Cadet.Assessments.submissions_by_grader_for_index(avenger_cr, %{
                "group" => "true",
                "isFullyGraded" => "false"
              })

            if Enum.count(ungraded_submissions) < ungraded_threshold do
              IO.puts("[AVENGER_BACKLOG] below threshold!")
            else
              IO.puts("[AVENGER_BACKLOG] SENDING_OUT")

              email =
                Email.avenger_backlog_email(
                  ntype.template_file_name,
                  avenger,
                  ungraded_submissions
                )

              {status, email} = Mailer.deliver_now(email)

              if status == :ok do
                Notifications.create_sent_notification(avenger_cr.id, email.html_body)
              end
            end
          end
        else
          IO.puts("[AVENGER_BACKLOG] course-level disabled")
        end
      end
    else
      IO.puts("[AVENGER_BACKLOG] system-level disabled!")
    end

    :ok
  end

  @impl Oban.Worker
  def perform(%Oban.Job{
        args:
          %{"notification_type" => notification_type, "submission_id" => submission_id} = _args
      })
      when notification_type == "assessment_submission" do
    notification_type =
      Cadet.Notifications.get_notification_type_by_name!("ASSESSMENT SUBMISSION")

    if is_system_enabled(notification_type.id) do
      submission = Cadet.Assessments.get_submission_by_id(submission_id)
      course_id = submission.assessment.course_id
      student_id = submission.student_id
      assessment_config_id = submission.assessment.config_id
      course_reg = Repo.get(Cadet.Accounts.CourseRegistration, submission.student_id)
      student = Cadet.Accounts.get_user(course_reg.user_id)
      avenger_cr = Cadet.Accounts.CourseRegistrations.get_avenger_of(student_id)
      avenger = avenger_cr.user

      cond do
        !is_course_enabled(notification_type.id, course_id, assessment_config_id) ->
          IO.puts("[ASSESSMENT_SUBMISSION] course-level disabled")

        !is_user_enabled(notification_type.id, avenger_cr.id) ->
          IO.puts("[ASSESSMENT_SUBMISSION] user-level disabled")

        true ->
          IO.puts("[ASSESSMENT_SUBMISSION] SENDING_OUT")

          email =
            Email.assessment_submission_email(
              notification_type.template_file_name,
              avenger,
              student,
              submission
            )

          {status, email} = Mailer.deliver_now(email)

          if status == :ok do
            Notifications.create_sent_notification(course_reg.id, email.html_body)
          end
      end
    else
      IO.puts("[ASSESSMENT_SUBMISSION] system-level disabled!")
    end
  end
end
