defmodule Cadet.EmailTest do
  use ExUnit.Case
  use Bamboo.Test
  alias Cadet.Email

  use Cadet.ChangesetCase, entity: Email

  test "avenger backlog email" do
    avenger_user = insert(:user, %{email: "test@gmail.com"})
    avenger = insert(:course_registration, %{user: avenger_user, role: :staff})

    ungraded_submissions =
      Jason.decode!(
        elem(Cadet.Assessments.all_submissions_by_grader_for_index(avenger, true, true), 1)
      )

    Cadet.Email.avenger_backlog_email("avenger_backlog", avenger_user, ungraded_submissions)

    avenger_email = avenger_user.email
    assert_delivered_email_matches(%{to: [{_, ^avenger_email}]})
  end
end
