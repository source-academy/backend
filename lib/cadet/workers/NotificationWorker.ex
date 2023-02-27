defmodule Cadet.Workers.NotificationWorker do
  @moduledoc """
  Contain oban workers for sending notifications
  """
  use Oban.Worker, queue: :notifications, max_attempts: 1
  alias Cadet.Email
  alias Cadet.Notifications

  defp is_system_enabled(notification_type_id) do
    Notifications.get_notification_type!(notification_type_id).is_enabled
  end

  defp is_course_enabled(notification_type_id, course_id, assessment_config_id) do
    Notifications.get_notification_config!(
      notification_type_id,
      course_id,
      assessment_config_id
    ).is_enabled
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

    if is_nil(pref) do
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
    notification_type_id = 2
    ungraded_threshold = 5

    ntype = Cadet.Notifications.get_notification_type!(notification_type_id)

    for course_id <- Cadet.Courses.get_all_course_ids() do
      avengers_crs = Cadet.Accounts.CourseRegistrations.get_staffs(course_id)

      for avenger_cr <- avengers_crs do
        avenger = Cadet.Accounts.get_user(avenger_cr.user_id)

        ungraded_submissions =
          Jason.decode!(
            elem(Cadet.Assessments.all_submissions_by_grader_for_index(avenger_cr, true, true), 1)
          )

        cond do
          length(ungraded_submissions) < ungraded_threshold ->
            IO.puts("[AVENGER_BACKLOG] below threshold!")

          !is_system_enabled(notification_type_id) ->
            IO.puts("[AVENGER_BACKLOG] system-level disabled!")

          !is_course_enabled(notification_type_id, course_id, nil) ->
            IO.puts("[AVENGER_BACKLOG] course-level disabled")

          true ->
            IO.puts("[AVENGER_BACKLOG] SENDING_OUT")
            Email.avenger_backlog_email(ntype.template_file_name, avenger, ungraded_submissions)
        end
      end
    end

    :ok
  end
end
