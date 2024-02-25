defmodule Cadet.Email do
  @moduledoc """
  Contains methods for sending email notifications.
  """
  use Bamboo.Phoenix, view: CadetWeb.EmailView
  import Bamboo.Email

  def avenger_backlog_email(template_file_name, avenger, ungraded_submissions) do
    if is_nil(avenger.email) do
      nil
    else
      ungraded_submissions =
        Enum.map(ungraded_submissions, fn submission ->
          Map.put(
            submission,
            :submission_url,
            build_submission_url(
              submission[:student_course_id],
              submission[:submission_id]
            )
          )
        end)
      base_email()
      |> to(avenger.email)
      |> assign(:avenger_name, avenger.name)
      |> assign(:submissions, ungraded_submissions)
      |> subject("Backlog for #{avenger.name}")
      |> render("#{template_file_name}.html")
    end
  end

  def assessment_submission_email(template_file_name, avenger, student, submission) do
    if is_nil(avenger.email) do
      nil
    else
      submission =
        Map.put(
          submission,
          :submission_url,
          build_submission_url(submission.assessment.course_id, submission.id)
        )

      base_email()
      |> to(avenger.email)
      |> assign(:avenger_name, avenger.name)
      |> assign(:student_name, student.name)
      |> assign(:submission, submission)
      |> subject("New submission for #{submission.assessment.title}")
      |> render("#{template_file_name}.html")
    end
  end

  defp base_email do
    new_email()
    |> from("noreply@sourceacademy.org")
    |> put_html_layout({CadetWeb.LayoutView, "email.html"})
  end

    # TODO update this to use frontend url
    defp build_submission_url(course_id, submission_id) do
      "https://sourceacademy.org/courses/#{course_id}/grading/#{submission_id}"
    end
end
