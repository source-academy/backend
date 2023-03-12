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
      base_email()
      |> to(avenger.email)
      |> assign(:avenger_name, avenger.name)
      |> assign(:student_name, student.name)
      |> assign(:assessment_title, submission.assessment.title)
      |> subject("New submission for #{submission.assessment.title}")
      |> render("#{template_file_name}.html")
    end
  end

  defp base_email do
    new_email()
    |> from("noreply@sourceacademy.org")
    |> put_html_layout({CadetWeb.LayoutView, "email.html"})
  end
end
