defmodule Cadet.Accounts.NotificationTest do
  alias Cadet.Accounts.Notification

  use Cadet.ChangesetCase, entity: Notification

  @required_fields ~w(type read user_id)a

  setup do
    assessment = insert(:assessment, %{is_published: true})
    avenger = insert(:user, %{role: :staff})
    student = insert(:user, %{role: :student})
    submission = insert(:submission, %{student: student, assessment: assessment})

    valid_params_for_student = %{
      type: :new,
      read: false,
      role: student.role,
      user_id: student.id,
      assessment_id: assessment.id
    }

    valid_params_for_avenger = %{
      type: :submitted,
      read: false,
      role: avenger.role,
      user_id: avenger.id,
      submission_id: submission.id
    }

    {:ok,
     %{
       assessment: assessment,
       student: student,
       submission: submission,
       valid_params_for_student: valid_params_for_student,
       valid_params_for_avenger: valid_params_for_avenger
     }}
  end

  describe "changeset" do
    test "valid notification params for student", %{valid_params_for_student: params} do
      assert_changeset(params, :valid)
    end

    test "valid notification params for avenger", %{valid_params_for_avenger: params} do
      assert_changeset(params, :valid)
    end

    test "valid notification params with question id", %{valid_params_for_student: params} do
      params = Map.put(params, :question_id, 12_345)

      assert_changeset(params, :valid)
    end

    test "invalid changeset missing required params for student", %{
      valid_params_for_student: params
    } do
      for field <- @required_fields ++ [:assessment_id] do
        params_missing_field = Map.delete(params, field)

        assert_changeset(params_missing_field, :invalid)
      end
    end

    test "invalid changeset missing required params for avenger", %{
      valid_params_for_avenger: params
    } do
      for field <- @required_fields ++ [:submission_id] do
        params_missing_field = Map.delete(params, field)

        assert_changeset(params_missing_field, :invalid)
      end
    end

    test "invalid role", %{valid_params_for_avenger: params} do
      params = Map.put(params, :role, :admin)

      assert_changeset(params, :invalid)
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
