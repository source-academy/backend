defmodule Cadet.Accounts.NotificationTest do
  alias Cadet.Accounts.Notification

  use Cadet.ChangesetCase, entity: Notification

  @required_fields ~w(type read user_id submission_id question_id)a

  setup do
    assessment = insert(:assessment, %{is_published: true})
    student = insert(:user, %{role: :student})
    submission = insert(:submission, %{student: student, assessment: assessment})
    programming_question = insert(:programming_question, %{assessment: assessment})

    valid_notification_params = %{
      type: :new,
      read: false,
      user_id: student.id,
      submission_id: submission.id,
      question_id: programming_question.id
    }

    {:ok,
     %{
       assessment: assessment,
       programming_question: programming_question,
       student: student,
       submission: submission,
       valid_notification_params: valid_notification_params
     }}
  end

  describe "changeset" do
    test "valid notification params", %{valid_notification_params: params} do
      assert_changeset(params, :valid)
    end

    test "invalid changeset missing required params", %{valid_notification_params: params} do
      for field <- @required_fields do
        params_missing_field = Map.delete(params, field)

        assert_changeset(params_missing_field, :invalid)
      end
    end
  end

  describe "repo" do
    test "fetch notifications when there are none" do
      # TODO
    end

    test "fetch notifications when there are some" do
      # TODO
    end

    test "fetch notifications when all read" do
      # TODO
    end

    test "create notification" do
      # TODO
    end

    test "acknowledge notification when not read" do
      # TODO
    end

    test "acknowledge notification when read" do
      # TODO
    end
  end
end
