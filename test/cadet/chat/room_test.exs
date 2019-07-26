defmodule Cadet.Chat.RoomTest do
  @moduledoc """
  All tests in this module use pre-recorded HTTP responses saved by ExVCR.
  this allows testing without the use of actual external Chatkit API calls.
  """

  use Cadet.DataCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  import Ecto.Query
  import ExUnit.CaptureLog

  alias Cadet.Assessments.Submission
  alias Cadet.Chat.Room
  alias Cadet.Repo

  setup do
    student = insert(:user, %{role: :student})
    assessment = insert(:assessment)
    submission = insert(:submission, %{student: student, assessment: assessment})
    question = insert(:question, %{assessment: assessment})

    answer_no_room_id =
      insert(:answer, %{
        submission_id: submission.id,
        question_id: question.id,
        room_id: nil
      })

    {:ok,
     %{
       student: student,
       answer_no_room_id: answer_no_room_id,
       assessment: assessment,
       submission: submission
     }}
  end

  describe "create a room on chatkit if answer does not have a room_id" do
    test "success", %{
      answer_no_room_id: answer,
      assessment: assessment,
      submission: submission,
      student: student
    } do
      use_cassette "chatkit/room#1" do
        Room.create_rooms(submission, answer, student)

        answer_db =
          Submission
          |> where(assessment_id: ^assessment.id)
          |> where(student_id: ^student.id)
          |> join(:inner, [s], a in assoc(s, :answers))
          |> select([_, a], a)
          |> Repo.one()

        assert answer_db.room_id == "19420137"
      end
    end

    test "user does not exist", %{
      answer_no_room_id: answer,
      assessment: assessment,
      submission: submission,
      student: student
    } do
      use_cassette "chatkit/room#2" do
        error = "services/chatkit/bad_request/users_not_found"
        error_description = "1 out of 2 users (including the room creator) could not be found"
        status_code = 400

        assert capture_log(fn ->
                 Room.create_rooms(submission, answer, student)

                 answer_db =
                   Submission
                   |> where(assessment_id: ^assessment.id)
                   |> where(student_id: ^student.id)
                   |> join(:inner, [s], a in assoc(s, :answers))
                   |> select([_, a], a)
                   |> Repo.one()

                 assert answer_db == answer
               end) =~
                 "Room creation failed: #{error}, #{error_description} (status code #{status_code}) " <>
                   "[user_id: #{student.id}, assessment_id: #{assessment.id}, question_id: #{
                     answer.question_id
                   }]"
      end
    end

    test "user does not have permission", %{
      answer_no_room_id: answer,
      assessment: assessment,
      submission: submission,
      student: student
    } do
      use_cassette "chatkit/room#3" do
        error = "services/chatkit_authorizer/authorization/missing_permission"
        error_description = "User does not have access to requested resource"
        status_code = 401

        assert capture_log(fn ->
                 Room.create_rooms(submission, answer, student)

                 answer_db =
                   Submission
                   |> where(assessment_id: ^assessment.id)
                   |> where(student_id: ^student.id)
                   |> join(:inner, [s], a in assoc(s, :answers))
                   |> select([_, a], a)
                   |> Repo.one()

                 assert answer_db == answer
               end) =~
                 "Room creation failed: #{error}, #{error_description} (status code #{status_code}) " <>
                   "[user_id: #{student.id}, assessment_id: #{assessment.id}, question_id: #{
                     answer.question_id
                   }]"
      end
    end
  end

  describe "do not create a room on chatkit if answer has a room_id" do
    test "success", %{
      student: student
    } do
      assessment = insert(:assessment)
      submission = insert(:submission, %{student: student, assessment: assessment})
      question = insert(:question, %{assessment: assessment})

      answer_with_room_id =
        insert(:answer, %{
          submission_id: submission.id,
          question_id: question.id
        })

      Room.create_rooms(submission, answer_with_room_id, student)

      answer_db =
        Submission
        |> where(assessment_id: ^assessment.id)
        |> where(student_id: ^student.id)
        |> join(:inner, [s], a in assoc(s, :answers))
        |> select([_, a], a)
        |> Repo.one()

      assert answer_db.room_id == answer_with_room_id.room_id
    end
  end
end
