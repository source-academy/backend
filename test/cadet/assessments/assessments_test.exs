defmodule Cadet.AssessmentsTest do
  use Cadet.DataCase

  import Cadet.{Factory, TestEntityHelper}
  alias Cadet.Assessments
  alias Cadet.Assessments.{Assessment, Question, SubmissionVotes, Submission, Answer}

  test "create assessments of all types" do
    course = insert(:course)
    config = insert(:assessment_config, %{type: "Test", course: course})
    course_id = course.id
    config_id = config.id

    {_res, assessment} =
      Assessments.create_assessment(%{
        course_id: course_id,
        title: "test",
        config_id: config_id,
        number: "#{config.type |> String.upcase()}#{Enum.random(0..10)}",
        open_at: Timex.now(),
        close_at: Timex.shift(Timex.now(), days: 7)
      })

    assert %{title: "test", config_id: ^config_id, course_id: ^course_id} = assessment
  end

  test "create programming question" do
    assessment = insert(:assessment)

    {:ok, question} =
      Assessments.create_question_for_assessment(
        %{
          type: :programming,
          library: build(:library),
          question: %{
            content: Faker.Pokemon.name(),
            prepend: "",
            template: Faker.Lorem.Shakespeare.as_you_like_it(),
            postpend: "",
            solution: Faker.Lorem.Shakespeare.hamlet()
          }
        },
        assessment.id
      )

    assert %{type: :programming} = question
  end

  test "create multiple choice question" do
    assessment = insert(:assessment)

    {:ok, question} =
      Assessments.create_question_for_assessment(
        %{
          type: :mcq,
          library: build(:library),
          question: %{
            content: Faker.Pokemon.name(),
            choices: Enum.map(0..2, &build(:mcq_choice, %{choice_id: &1, is_correct: &1 == 0}))
          }
        },
        assessment.id
      )

    assert %{type: :mcq} = question
  end

  test "create voting question" do
    assessment = insert(:assessment)

    {:ok, question} =
      Assessments.create_question_for_assessment(
        %{
          type: :voting,
          library: build(:library),
          question: %{
            content: Faker.Pokemon.name(),
            contest_number: assessment.number,
            reveal_hours: 48,
            token_divider: 50
          }
        },
        assessment.id
      )

    assert %{type: :voting} = question
  end

  test "create question when there already exists questions" do
    assessment = insert(:assessment)
    _ = insert(:mcq_question, assessment: assessment, display_order: 1)

    {:ok, question} =
      Assessments.create_question_for_assessment(
        %{
          type: :mcq,
          library: build(:library),
          question: %{
            content: Faker.Pokemon.name(),
            choices: Enum.map(0..2, &build(:mcq_choice, %{choice_id: &1, is_correct: &1 == 0}))
          }
        },
        assessment.id
      )

    assert %{display_order: 2} = question
  end

  test "create invalid question" do
    assessment = insert(:assessment)

    assert {:error, _} = Assessments.create_question_for_assessment(%{}, assessment.id)
  end

  test "publish assessment" do
    course = insert(:course)
    config = insert(:assessment_config, %{course: course})
    assessment = insert(:assessment, %{is_published: false, course: course, config: config})

    {:ok, assessment} = Assessments.publish_assessment(assessment.id)
    assert assessment.is_published == true
  end

  describe "Update assessments" do
    test "update assessment" do
      course = insert(:course)
      config = insert(:assessment_config, %{course: course})
      assessment = insert(:assessment, %{title: "assessment", course: course, config: config})

      Assessments.update_assessment(assessment.id, %{title: "changed_assessment"})

      assessment = Repo.get(Assessment, assessment.id)

      assert assessment.title == "changed_assessment"
    end

    test "update grading info for assessment" do
      course = insert(:course)
      config = insert(:assessment_config, %{course: course})
      assessment = insert(:assessment, %{config: config, course: course, is_published: false})

      student = insert(:course_registration, %{course: course, role: :student})
      question = insert(:question, %{assessment: assessment})

      submission =
        insert(:submission, %{
          assessment: assessment,
          team: nil,
          student: student,
          status: :attempting
        })

      assert {:error, {:forbidden, "User is not permitted to grade."}} =
               Assessments.update_grading_info(
                 %{submission: submission, question: question},
                 %{},
                 student
               )
    end

    test "force update assessment with invalid params" do
      course = insert(:course)
      config = insert(:assessment_config, %{course: course})

      assessment =
        insert(:assessment, %{
          config: config,
          course: course,
          open_at: Timex.shift(Timex.now(), days: -5),
          close_at: Timex.shift(Timex.now(), hours: +5),
          is_published: true
        })

      assessment_params = %{
        number: assessment.number,
        course_id: course.id
      }

      question_params = %{
        assessment: assessment,
        type: :programming
      }

      assert {:error, "Question count is different"} =
               Assessments.insert_or_update_assessments_and_questions(
                 assessment_params,
                 question_params,
                 true
               )
    end
  end

  test "update question" do
    question = insert(:question, display_order: 1)
    Assessments.update_question(question.id, %{display_order: 5})
    question = Repo.get(Question, question.id)
    assert question.display_order == 5
  end

  test "delete question" do
    question = insert(:question)
    Assessments.delete_question(question.id)
    assert Repo.get(Question, question.id) == nil
  end

  describe "team assessments" do
    test "cannot answer questions without a team" do
      course = insert(:course)
      config = insert(:assessment_config, %{course: course})
      assessment = insert(:assessment, %{config: config, course: course, max_team_size: 10})
      question = insert(:question, %{assessment: assessment})
      student = insert(:course_registration, %{course: course, role: :student})

      assert Assessments.answer_question(question, student, "answer", false) ==
               {:error, {:bad_request, "Your existing Team has been deleted!"}}
    end

    test "answer questions with a team" do
      course = insert(:course)
      config = insert(:assessment_config, %{course: course})
      assessment = insert(:assessment, %{config: config, course: course, max_team_size: 10})
      question = insert(:question, %{assessment: assessment, type: :programming})
      student1 = insert(:course_registration, %{course: course, role: :student})
      student2 = insert(:course_registration, %{course: course, role: :student})
      teammember1 = insert(:team_member, %{student: student1})
      teammember2 = insert(:team_member, %{student: student2})
      team = insert(:team, %{assessment: assessment, team_members: [teammember1, teammember2]})

      submission =
        insert(:submission, %{
          assessment: assessment,
          team: team,
          student: nil,
          status: :attempting
        })

      _answer =
        insert(:answer, submission: submission, question: question, answer: %{code: "f => f(f);"})

      assert Assessments.answer_question(question, student1, "answer", false) == {:ok, nil}
    end

    test "assessments with questions and answers" do
      course = insert(:course)
      config = insert(:assessment_config, %{course: course})
      assessment = insert(:assessment, %{config: config, course: course, max_team_size: 10})
      student = insert(:course_registration, %{course: course, role: :student})

      assert {:ok, _} = Assessments.assessment_with_questions_and_answers(assessment, student)
    end

    test "overdue assessments with questions and answers" do
      course = insert(:course)
      config = insert(:assessment_config, %{course: course})

      assessment =
        insert(:assessment, %{
          config: config,
          course: course,
          max_team_size: 10,
          open_at: Timex.shift(Timex.now(), days: -15),
          close_at: Timex.shift(Timex.now(), days: -5),
          is_published: true,
          password: "123"
        })

      student = insert(:course_registration, %{course: course, role: :student})

      assert {:ok, _} =
               Assessments.assessment_with_questions_and_answers(assessment, student, "123")
    end

    test "team assessments with questions and answers" do
      course = insert(:course)
      config = insert(:assessment_config, %{course: course})

      assessment =
        insert(:assessment, %{
          config: config,
          course: course,
          max_team_size: 10,
          open_at: Timex.shift(Timex.now(), days: -15),
          close_at: Timex.shift(Timex.now(), days: +5),
          is_published: true
        })

      group = insert(:group, %{name: "group"})
      student1 = insert(:course_registration, %{course: course, role: :student, group: group})
      student2 = insert(:course_registration, %{course: course, role: :student, group: group})

      teammember1 = insert(:team_member, %{student: student1})
      teammember2 = insert(:team_member, %{student: student2})
      team = insert(:team, %{assessment: assessment, team_members: [teammember1, teammember2]})

      submission =
        insert(:submission, %{
          assessment: assessment,
          team: team,
          student: nil,
          status: :submitted
        })

      assert {:ok, _} = Assessments.assessment_with_questions_and_answers(assessment, student1)
      assert submission.id == Assessments.get_submission(assessment.id, student1).id
    end

    test "create empty submission for team assessment" do
      course = insert(:course)
      config = insert(:assessment_config, %{course: course})

      team_assessment =
        insert(:assessment, %{
          config: config,
          course: course,
          max_team_size: 10,
          open_at: Timex.shift(Timex.now(), days: -5),
          close_at: Timex.shift(Timex.now(), hours: +5),
          is_published: true
        })

      group = insert(:group, %{name: "group"})

      student1 = insert(:course_registration, %{course: course, role: :student, group: group})
      student2 = insert(:course_registration, %{course: course, role: :student, group: group})
      teammember1 = insert(:team_member, %{student: student1})
      teammember2 = insert(:team_member, %{student: student2})

      team =
        insert(:team, %{assessment: team_assessment, team_members: [teammember1, teammember2]})

      question = insert(:question, %{assessment: team_assessment, type: :programming})

      assert {:ok, _} = Assessments.answer_question(question, student1, "answer", false)

      submission =
        Submission
        |> where([s], s.team_id == ^team.id)
        |> Repo.all()

      assert length(submission) == 1
    end

    @tag authenticate: :staff
    test "unsubmit team assessment" do
      course = insert(:course)
      config = insert(:assessment_config, %{course: course})

      team_assessment =
        insert(:assessment, %{
          config: config,
          course: course,
          max_team_size: 10,
          open_at: Timex.shift(Timex.now(), days: -5),
          close_at: Timex.shift(Timex.now(), hours: +5),
          is_published: true
        })

      group = insert(:group, %{name: "group"})
      avenger = insert(:course_registration, %{course: course, role: :staff, group: group})

      student1 = insert(:course_registration, %{course: course, role: :student, group: group})
      student2 = insert(:course_registration, %{course: course, role: :student, group: group})
      teammember1 = insert(:team_member, %{student: student1})
      teammember2 = insert(:team_member, %{student: student2})

      team =
        insert(:team, %{assessment: team_assessment, team_members: [teammember1, teammember2]})

      submission =
        insert(:submission, %{
          assessment: team_assessment,
          team: team,
          student: nil,
          status: :submitted
        })

      assert {:ok, _} = Assessments.unsubmit_submission(submission.id, avenger)
    end

    @tag authenticate: :staff
    test "delete team assessment with associating submission" do
      course = insert(:course)
      config = insert(:assessment_config, %{course: course})

      assessment =
        insert(:assessment, %{
          config: config,
          course: course,
          open_at: Timex.shift(Timex.now(), days: -5),
          close_at: Timex.shift(Timex.now(), hours: +5),
          is_published: true
        })

      student = insert(:course_registration, %{course: course, role: :student})
      question = insert(:question, %{assessment: assessment})

      submission =
        insert(:submission, %{
          assessment: assessment,
          team: nil,
          student: student,
          status: :attempting
        })

      _answer =
        insert(:answer, submission: submission, question: question, answer: %{code: "f => f(f);"})

      assert {:ok, _} = Assessments.delete_assessment(assessment.id)
    end

    test "get user xp for team assessment" do
      course = insert(:course)
      config = insert(:assessment_config, %{course: course})

      team_assessment =
        insert(:assessment, %{
          config: config,
          course: course,
          max_team_size: 10,
          open_at: Timex.shift(Timex.now(), days: -5),
          close_at: Timex.shift(Timex.now(), hours: +5),
          is_published: true
        })

      group = insert(:group, %{name: "group"})

      student1 = insert(:course_registration, %{course: course, role: :student, group: group})
      student2 = insert(:course_registration, %{course: course, role: :student, group: group})
      teammember1 = insert(:team_member, %{student: student1})
      teammember2 = insert(:team_member, %{student: student2})

      _team =
        insert(:team, %{assessment: team_assessment, team_members: [teammember1, teammember2]})

      assert Assessments.assessments_total_xp(student1) == 0
    end
  end

  describe "contest voting" do
    test "inserts votes into submission_votes table if contest has closed" do
      course = insert(:course)
      config = insert(:assessment_config)
      # contest assessment that has closed
      closed_contest_assessment =
        insert(:assessment,
          is_published: true,
          open_at: Timex.shift(Timex.now(), days: -5),
          close_at: Timex.shift(Timex.now(), hours: -1),
          course: course,
          config: config
        )

      contest_question = insert(:programming_question, assessment: closed_contest_assessment)
      voting_assessment = insert(:assessment, %{course: course})

      question =
        insert(:voting_question, %{
          assessment: voting_assessment,
          question:
            build(:voting_question_content, contest_number: closed_contest_assessment.number)
        })

      students =
        insert_list(6, :course_registration, %{
          role: :student,
          course: course
        })

      Enum.map(students, fn student ->
        submission =
          insert(:submission,
            student: student,
            assessment: contest_question.assessment,
            status: "submitted"
          )

        insert(:answer,
          answer: %{code: "return 2;"},
          submission: submission,
          question: contest_question
        )
      end)

      unattempted_student = insert(:course_registration, %{role: :student, course: course})

      # unattempted submission will automatically be submitted after the assessment closes.
      unattempted_submission =
        insert(:submission,
          student: unattempted_student,
          assessment: contest_question.assessment,
          status: "submitted"
        )

      insert(:answer,
        answer: %{
          code: "// question was left blank by student"
        },
        submission: unattempted_submission,
        question: contest_question
      )

      Assessments.insert_voting(course.id, contest_question.assessment.number, question.id)

      # students with own contest submissions will vote for 5 entries
      # students without own contest submissin will vote for 6 entries
      assert SubmissionVotes |> where(question_id: ^question.id) |> Repo.all() |> length() ==
               6 * 5 + 6
    end

    test "does not insert entries for voting if contest is still open" do
      course = insert(:course)
      config = insert(:assessment_config)
      # contest assessment that is still open
      open_contest_assessment =
        insert(:assessment,
          is_published: true,
          open_at: Timex.shift(Timex.now(), days: -5),
          close_at: Timex.shift(Timex.now(), hours: 1),
          course: course,
          config: config
        )

      contest_question = insert(:programming_question, assessment: open_contest_assessment)
      voting_assessment = insert(:assessment, %{course: course})

      question =
        insert(:voting_question, %{
          assessment: voting_assessment,
          question:
            build(:voting_question_content, contest_number: open_contest_assessment.number)
        })

      students =
        insert_list(6, :course_registration, %{
          role: :student,
          course: course
        })

      Enum.map(students, fn student ->
        submission =
          insert(:submission,
            student: student,
            assessment: contest_question.assessment,
            status: "submitted"
          )

        insert(:answer,
          answer: %{code: "return 2;"},
          submission: submission,
          question: contest_question
        )
      end)

      Assessments.insert_voting(course.id, contest_question.assessment.number, question.id)

      # No entries should be released for students to vote on while the contest is still open
      assert SubmissionVotes |> where(question_id: ^question.id) |> Repo.all() |> length() == 0
    end

    test "function that reassign voting after voting is assigned" do
      course = insert(:course)
      config = insert(:assessment_config)
      # contest assessment that has closed
      closed_contest_assessment =
        insert(:assessment,
          is_published: true,
          open_at: Timex.shift(Timex.now(), days: -5),
          close_at: Timex.shift(Timex.now(), hours: -1),
          course: course,
          config: config
        )

      contest_question = insert(:programming_question, assessment: closed_contest_assessment)
      voting_assessment = insert(:assessment, %{course: course})

      question =
        insert(:voting_question, %{
          assessment: voting_assessment,
          question:
            build(:voting_question_content, contest_number: closed_contest_assessment.number)
        })

      students =
        insert_list(6, :course_registration, %{
          role: :student,
          course: course
        })

      Enum.map(students, fn student ->
        submission =
          insert(:submission,
            student: student,
            assessment: contest_question.assessment,
            status: "submitted"
          )

        insert(:answer,
          answer: %{code: "return 2;"},
          submission: submission,
          question: contest_question
        )
      end)

      unattempted_student = insert(:course_registration, %{role: :student, course: course})

      # unattempted submission will automatically be submitted after the assessment closes.
      unattempted_submission =
        insert(:submission,
          student: unattempted_student,
          assessment: contest_question.assessment,
          status: "submitted"
        )

      insert(:answer,
        answer: %{
          code: "// question was left blank by student"
        },
        submission: unattempted_submission,
        question: contest_question
      )

      Assessments.insert_voting(course.id, contest_question.assessment.number, question.id)
      Assessments.reassign_voting(voting_assessment.id, true)

      # students with own contest submissions will vote for 5 entries
      # students without own contest submissin will vote for 6 entries
      assert SubmissionVotes |> where(question_id: ^question.id) |> Repo.all() |> length() ==
               6 * 5 + 6
    end

    test "function that checks for closed contests and releases entries into voting pool" do
      course = insert(:course)
      config = insert(:assessment_config)
      # contest assessment that has closed
      closed_contest_assessment =
        insert(:assessment,
          is_published: true,
          open_at: Timex.shift(Timex.now(), days: -5),
          close_at: Timex.shift(Timex.now(), hours: -1),
          course: course,
          config: config
        )

      # contest assessment that is still open
      open_contest_assessment =
        insert(:assessment,
          is_published: true,
          open_at: Timex.shift(Timex.now(), days: -5),
          close_at: Timex.shift(Timex.now(), hours: 1),
          course: course,
          config: config
        )

      # contest assessment that is closed but insert_voting has already been done
      compiled_contest_assessment =
        insert(:assessment,
          is_published: true,
          open_at: Timex.shift(Timex.now(), days: -5),
          close_at: Timex.shift(Timex.now(), hours: -1),
          course: course,
          config: config
        )

      closed_contest_question =
        insert(:programming_question, assessment: closed_contest_assessment)

      open_contest_question = insert(:programming_question, assessment: open_contest_assessment)

      compiled_contest_question =
        insert(:programming_question, assessment: compiled_contest_assessment)

      closed_voting_assessment = insert(:assessment, %{course: course})
      open_voting_assessment = insert(:assessment, %{course: course})
      compiled_voting_assessment = insert(:assessment, %{course: course})
      # voting assessment that references an invalid contest number
      invalid_voting_assessment = insert(:assessment, %{course: course})

      closed_question =
        insert(:voting_question, %{
          assessment: closed_voting_assessment,
          question:
            build(:voting_question_content, contest_number: closed_contest_assessment.number)
        })

      open_question =
        insert(:voting_question, %{
          assessment: open_voting_assessment,
          question:
            build(:voting_question_content, contest_number: open_contest_assessment.number)
        })

      compiled_question =
        insert(:voting_question, %{
          assessment: compiled_voting_assessment,
          question:
            build(:voting_question_content, contest_number: compiled_contest_assessment.number)
        })

      invalid_question =
        insert(:voting_question, %{
          assessment: invalid_voting_assessment,
          question: build(:voting_question_content, contest_number: "test_invalid")
        })

      students =
        insert_list(10, :course_registration, %{
          role: :student,
          course: course
        })

      first_four = Enum.slice(students, 0..3)
      last_six = Enum.slice(students, 4..9)

      Enum.map(first_four, fn student ->
        submission =
          insert(:submission,
            student: student,
            assessment: compiled_contest_question.assessment,
            status: "submitted"
          )

        insert(:answer,
          answer: %{code: "return 2;"},
          submission: submission,
          question: compiled_contest_question
        )
      end)

      # Only the compiled_assessment has already released entries into voting pool
      Assessments.insert_voting(
        course.id,
        compiled_contest_question.assessment.number,
        compiled_question.id
      )

      assert SubmissionVotes |> where(question_id: ^closed_question.id) |> Repo.all() |> length() ==
               0

      assert SubmissionVotes |> where(question_id: ^open_question.id) |> Repo.all() |> length() ==
               0

      assert SubmissionVotes
             |> where(question_id: ^compiled_question.id)
             |> Repo.all()
             |> length() == 4 * 3 + 6 * 4

      assert SubmissionVotes |> where(question_id: ^invalid_question.id) |> Repo.all() |> length() ==
               0

      Enum.map(students, fn student ->
        submission =
          insert(:submission,
            student: student,
            assessment: closed_contest_question.assessment,
            status: "submitted"
          )

        insert(:answer,
          answer: %{code: "return 2;"},
          submission: submission,
          question: closed_contest_question
        )
      end)

      Enum.map(students, fn student ->
        submission =
          insert(:submission,
            student: student,
            assessment: open_contest_question.assessment,
            status: "submitted"
          )

        insert(:answer,
          answer: %{code: "return 2;"},
          submission: submission,
          question: open_contest_question
        )
      end)

      Enum.map(last_six, fn student ->
        submission =
          insert(:submission,
            student: student,
            assessment: compiled_contest_question.assessment,
            status: "submitted"
          )

        insert(:answer,
          answer: %{code: "return 2;"},
          submission: submission,
          question: compiled_contest_question
        )
      end)

      # fetching all unassigned voting questions should only yield open and closed questions
      unassigned_voting_questions = Assessments.fetch_unassigned_voting_questions()
      assert Enum.count(unassigned_voting_questions) == 2

      unassigned_voting_question_ids =
        Enum.map(unassigned_voting_questions, fn q -> q.question_id end)

      assert closed_question.id in unassigned_voting_question_ids
      assert open_question.id in unassigned_voting_question_ids

      Assessments.update_final_contest_entries()

      # only the closed_contest should have been updated
      assert SubmissionVotes |> where(question_id: ^closed_question.id) |> Repo.all() |> length() ==
               10 * 9

      assert SubmissionVotes |> where(question_id: ^open_question.id) |> Repo.all() |> length() ==
               0

      assert SubmissionVotes
             |> where(question_id: ^compiled_question.id)
             |> Repo.all()
             |> length() == 4 * 3 + 6 * 4

      assert SubmissionVotes |> where(question_id: ^invalid_question.id) |> Repo.all() |> length() ==
               0
    end

    test "create voting parameters with invalid contest number" do
      contest_question = insert(:programming_question)
      question = insert(:voting_question)

      {status, _} =
        Assessments.insert_voting(
          insert(:course).id,
          contest_question.assessment.number,
          question.id
        )

      assert status == :error

      {status, _} =
        Assessments.insert_voting(contest_question.assessment.course_id, "", question.id)

      assert status == :error
    end

    test "deletes submission_votes when assessment is deleted" do
      course = insert(:course)
      config = insert(:assessment_config)
      # contest assessment that has closed
      contest_assessment =
        insert(:assessment,
          is_published: true,
          open_at: Timex.shift(Timex.now(), days: -5),
          close_at: Timex.shift(Timex.now(), hours: -1),
          course: course,
          config: config
        )

      contest_question = insert(:programming_question, assessment: contest_assessment)
      voting_assessment = insert(:assessment, %{course: course, config: config})
      question = insert(:voting_question, assessment: voting_assessment)
      students = insert_list(5, :course_registration, %{role: :student, course: course})

      Enum.map(students, fn student ->
        submission =
          insert(:submission,
            student: student,
            assessment: contest_question.assessment,
            status: "submitted"
          )

        insert(:answer,
          answer: %{code: "return 2;"},
          submission: submission,
          question: contest_question
        )
      end)

      Assessments.insert_voting(course.id, contest_question.assessment.number, question.id)
      assert Repo.exists?(SubmissionVotes, question_id: question.id)

      Assessments.delete_assessment(voting_assessment.id)
      refute Repo.exists?(SubmissionVotes, question_id: question.id)
    end

    test "does not delete contest assessment if referencing voting assessment is present" do
      course = insert(:course)
      config = insert(:assessment_config)

      contest_assessment =
        insert(:assessment,
          is_published: true,
          open_at: Timex.shift(Timex.now(), days: -5),
          close_at: Timex.shift(Timex.now(), hours: -1),
          course: course,
          config: config,
          number: "test"
        )

      voting_assessment = insert(:assessment, %{course: course, config: config})

      # insert voting question that references the contest assessment
      _voting_question =
        insert(:voting_question, %{
          assessment: voting_assessment,
          question: build(:voting_question_content, contest_number: contest_assessment.number)
        })

      error_message = {:bad_request, "Contest voting for this contest is still up"}

      assert {:error, ^error_message} = Assessments.delete_assessment(contest_assessment.id)
      # deletion should fail
      assert Assessment |> where(id: ^contest_assessment.id) |> Repo.exists?()
    end

    test "deletes contest assessment if voting assessment references same number but different course" do
      course_1 = insert(:course)
      course_2 = insert(:course)
      config = insert(:assessment_config)

      contest_assessment =
        insert(:assessment,
          is_published: true,
          open_at: Timex.shift(Timex.now(), days: -5),
          close_at: Timex.shift(Timex.now(), hours: -1),
          course: course_1,
          config: config,
          number: "test"
        )

      voting_assessment = insert(:assessment, %{course: course_2, config: config})

      # insert voting question from a different course that references the same contest number
      _voting_question =
        insert(:voting_question, %{
          assessment: voting_assessment,
          question: build(:voting_question_content, contest_number: contest_assessment.number)
        })

      assert {:ok, _} = Assessments.delete_assessment(contest_assessment.id)
      # deletion should succeed
      refute Assessment |> where(id: ^contest_assessment.id) |> Repo.exists?()
    end
  end

  describe "contest voting leaderboard utility functions" do
    setup do
      course = insert(:course)
      config = insert(:assessment_config)
      contest_assessment = insert(:assessment, %{course: course, config: config})
      voting_assessment = insert(:assessment, %{course: course, config: config})
      voting_question = insert(:voting_question, assessment: voting_assessment)

      # generate 5 students
      student_list = insert_list(5, :course_registration, %{course: course, role: :student})

      # generate contest submission for each student
      submission_list =
        Enum.map(
          student_list,
          fn student ->
            insert(
              :submission,
              student: student,
              assessment: contest_assessment,
              status: "submitted"
            )
          end
        )

      # generate answer for each student
      ans_list =
        Enum.map(
          submission_list,
          fn submission ->
            insert(
              :answer,
              answer: build(:programming_answer),
              submission: submission,
              question: voting_question
            )
          end
        )

      # generate submission votes for each student
      _submission_votes =
        Enum.map(
          student_list,
          fn student ->
            Enum.map(
              Enum.with_index(submission_list),
              fn {submission, index} ->
                insert(
                  :submission_vote,
                  score: 10 - index,
                  voter: student,
                  submission: submission,
                  question: voting_question
                )
              end
            )
          end
        )

      %{answers: ans_list, question_id: voting_question.id, student_list: student_list}
    end

    test "computes correct relative_score with lexing/penalty and fetches highest x relative_score correctly",
         %{answers: _answers, question_id: question_id, student_list: _student_list} do
      Assessments.compute_relative_score(question_id)

      top_x_ans = Assessments.fetch_top_relative_score_answers(question_id, 5)

      assert get_answer_relative_scores(top_x_ans) == expected_top_relative_scores(5, 50)

      x = 3
      top_x_ans = Assessments.fetch_top_relative_score_answers(question_id, x)

      # verify that top x ans are queried correctly
      assert get_answer_relative_scores(top_x_ans) == expected_top_relative_scores(3, 50)
    end
  end

  describe "contest leaderboard updating functions" do
    setup do
      course = insert(:course)
      config = insert(:assessment_config)
      current_contest_assessment = insert(:assessment, %{course: course, config: config})
      # contest_voting assessment that is still ongoing
      current_assessment =
        insert(:assessment,
          is_published: true,
          open_at: Timex.shift(Timex.now(), days: -1),
          close_at: Timex.shift(Timex.now(), days: +1),
          course: course,
          config: config
        )

      current_question = insert(:voting_question, assessment: current_assessment)

      yesterday_contest_assessment = insert(:assessment, %{course: course, config: config})
      # contest_voting assessment closed yesterday
      yesterday_assessment =
        insert(:assessment,
          is_published: true,
          open_at: Timex.shift(Timex.now(), days: -5),
          close_at: Timex.shift(Timex.now(), hours: -4),
          course: course,
          config: config
        )

      yesterday_question = insert(:voting_question, assessment: yesterday_assessment)

      past_contest_assessment = insert(:assessment, %{course: course, config: config})
      # contest voting assessment closed >1 day ago
      past_assessment =
        insert(:assessment,
          is_published: true,
          open_at: Timex.shift(Timex.now(), days: -5),
          close_at: Timex.shift(Timex.now(), days: -4),
          course: course,
          config: config
        )

      past_question =
        insert(:voting_question,
          assessment: past_assessment
        )

      # generate 5 students
      student_list = insert_list(5, :course_registration, %{course: course, role: :student})

      # generate contest submission for each user
      current_submission_list =
        Enum.map(
          student_list,
          fn student ->
            insert(
              :submission,
              student: student,
              assessment: current_contest_assessment,
              status: "submitted"
            )
          end
        )

      yesterday_submission_list =
        Enum.map(
          student_list,
          fn student ->
            insert(
              :submission,
              student: student,
              assessment: yesterday_contest_assessment,
              status: "submitted"
            )
          end
        )

      past_submission_list =
        Enum.map(
          student_list,
          fn student ->
            insert(
              :submission,
              student: student,
              assessment: past_contest_assessment,
              status: "submitted"
            )
          end
        )

      # generate answers for each submission for each student
      Enum.map(
        current_submission_list,
        fn submission ->
          insert(
            :answer,
            answer: build(:programming_answer),
            submission: submission,
            question: current_question
          )
        end
      )

      Enum.map(
        yesterday_submission_list,
        fn submission ->
          insert(
            :answer,
            answer: build(:programming_answer),
            submission: submission,
            question: yesterday_question
          )
        end
      )

      Enum.map(
        past_submission_list,
        fn submission ->
          insert(
            :answer,
            answer: build(:programming_answer),
            submission: submission,
            question: past_question
          )
        end
      )

      # generate votes by each user for each contest entry
      _current_assessment_votes =
        Enum.map(
          student_list,
          fn student ->
            Enum.map(
              Enum.with_index(current_submission_list),
              fn {submission, index} ->
                insert(
                  :submission_vote,
                  score: 10 - index,
                  voter: student,
                  submission: submission,
                  question: current_question
                )
              end
            )
          end
        )

      _yesterday_assessment_votes =
        Enum.map(
          student_list,
          fn student ->
            Enum.map(
              Enum.with_index(yesterday_submission_list),
              fn {submission, index} ->
                insert(
                  :submission_vote,
                  score: 10 - index,
                  voter: student,
                  submission: submission,
                  question: yesterday_question
                )
              end
            )
          end
        )

      _past_assessment_votes =
        Enum.map(
          student_list,
          fn student ->
            Enum.map(
              Enum.with_index(past_submission_list),
              fn {submission, index} ->
                insert(
                  :submission_vote,
                  score: 10 - index,
                  voter: student,
                  submission: submission,
                  question: past_question
                )
              end
            )
          end
        )

      %{
        yesterday_question: yesterday_question,
        current_question: current_question,
        past_question: past_question
      }
    end

    test "fetch_voting_questions_due_yesterday only fetching voting questions closed yesterday",
         %{
           yesterday_question: yesterday_question,
           current_question: _current_question,
           past_question: _past_question
         } do
      assert get_question_ids([yesterday_question]) ==
               get_question_ids(Assessments.fetch_voting_questions_due_yesterday())
    end

    test "fetch_active_voting_questions only fetches active voting questions",
         %{
           yesterday_question: _yesterday_question,
           current_question: current_question,
           past_question: _past_question
         } do
      assert get_question_ids([current_question]) ==
               get_question_ids(Assessments.fetch_active_voting_questions())
    end

    test "update_final_contest_leaderboards correctly updates leaderboards that voting closed yesterday",
         %{
           yesterday_question: yesterday_question,
           current_question: current_question,
           past_question: past_question
         } do
      Assessments.update_final_contest_leaderboards()

      # does not update scores for voting assessments closed  >1 days and those ongoing ago
      assert get_answer_relative_scores(
               Assessments.fetch_top_relative_score_answers(past_question.id, 1)
             ) == [0.0, 0.0, 0.0, 0.0, 0.0]

      assert get_answer_relative_scores(
               Assessments.fetch_top_relative_score_answers(current_question.id, 1)
             ) == [0.0, 0.0, 0.0, 0.0, 0.0]

      assert get_answer_relative_scores(
               Assessments.fetch_top_relative_score_answers(yesterday_question.id, 5)
             ) == expected_top_relative_scores(5, 50)
    end

    test "update_rolling_contest_leaderboards correcly updates leaderboards which voting is active",
         %{
           yesterday_question: yesterday_question,
           current_question: current_question,
           past_question: past_question
         } do
      Assessments.update_rolling_contest_leaderboards()

      # does not update scores for voting assessments closed >1 days ago
      assert get_answer_relative_scores(
               Assessments.fetch_top_relative_score_answers(past_question.id, 1)
             ) == [0.0, 0.0, 0.0, 0.0, 0.0]

      assert get_answer_relative_scores(
               Assessments.fetch_top_relative_score_answers(yesterday_question.id, 1)
             ) == [0.0, 0.0, 0.0, 0.0, 0.0]

      assert get_answer_relative_scores(
               Assessments.fetch_top_relative_score_answers(current_question.id, 5)
             ) == expected_top_relative_scores(5, 50)
    end
  end

  describe "get combined xp function" do
    setup do
      course_registration = insert(:course_registration)
      course_id = course_registration.course_id
      user_id = course_registration.user_id
      course_reg_id = course_registration.id

      %{
        test_cr: course_registration,
        course_id: course_id,
        user_id: user_id,
        course_reg_id: course_reg_id
      }
    end

    test "achievement, one completed goal", %{
      test_cr: test_cr,
      course_id: course_id,
      user_id: user_id,
      course_reg_id: course_reg_id
    } do
      course = test_cr.course

      assessment = insert(:assessment, %{is_published: true, course: course})
      question = insert(:question, %{assessment: assessment})

      submission =
        insert(:submission, %{
          assessment: assessment,
          student: test_cr,
          status: :submitted,
          xp_bonus: 100,
          is_grading_published: true
        })

      insert(:answer, %{
        question: question,
        submission: submission,
        xp: 20,
        xp_adjustment: -10
      })

      goal =
        insert(
          :goal,
          Map.merge(
            goal_literal(1),
            %{
              course: course,
              progress: [
                %{
                  count: 1,
                  completed: true,
                  course_reg_id: test_cr.id
                }
              ]
            }
          )
        )

      insert(:achievement, %{
        course: course,
        title: "Rune Master",
        is_task: true,
        is_variable_xp: false,
        position: 1,
        xp: 100,
        card_tile_url:
          "https://source-academy-assets.s3-ap-southeast-1.amazonaws.com/achievement/card-tile/rune-master-tile.png",
        goals: [
          %{goal_uuid: goal.uuid}
        ]
      })

      resp =
        Assessments.user_total_xp(
          course_id,
          user_id,
          course_reg_id
        )

      assert resp == 210
    end

    test "achievement, one incomplete goal", %{
      test_cr: test_cr,
      course_id: course_id,
      user_id: user_id,
      course_reg_id: course_reg_id
    } do
      course = test_cr.course

      assessment = insert(:assessment, %{is_published: true, course: course})
      question = insert(:question, %{assessment: assessment})

      submission =
        insert(:submission, %{
          assessment: assessment,
          student: test_cr,
          status: :submitted,
          xp_bonus: 100,
          is_grading_published: true
        })

      insert(:answer, %{
        question: question,
        submission: submission,
        xp: 20,
        xp_adjustment: -10
      })

      goal =
        insert(
          :goal,
          Map.merge(
            goal_literal(1),
            %{
              course: course,
              progress: [
                %{
                  count: 0,
                  completed: true,
                  course_reg_id: test_cr.id
                }
              ]
            }
          )
        )

      insert(:achievement, %{
        course: course,
        title: "Rune Master",
        is_task: true,
        is_variable_xp: false,
        position: 1,
        xp: 100,
        card_tile_url:
          "https://source-academy-assets.s3-ap-southeast-1.amazonaws.com/achievement/card-tile/rune-master-tile.png",
        goals: [
          %{goal_uuid: goal.uuid}
        ]
      })

      resp =
        Assessments.user_total_xp(
          course_id,
          user_id,
          course_reg_id
        )

      assert resp == 110
    end

    test "achievement, one completed and one incomplete goal",
         %{
           test_cr: test_cr,
           course_id: course_id,
           user_id: user_id,
           course_reg_id: course_reg_id
         } do
      course = test_cr.course

      assessment = insert(:assessment, %{is_published: true, course: course})
      question = insert(:question, %{assessment: assessment})

      submission =
        insert(:submission, %{
          assessment: assessment,
          student: test_cr,
          status: :submitted,
          xp_bonus: 100,
          is_grading_published: true
        })

      insert(:answer, %{
        question: question,
        submission: submission,
        xp: 20,
        xp_adjustment: -10
      })

      goal_complete =
        insert(
          :goal,
          Map.merge(
            goal_literal(1),
            %{
              course: course,
              progress: [
                %{
                  count: 1,
                  completed: true,
                  course_reg_id: test_cr.id
                }
              ]
            }
          )
        )

      goal_incomplete =
        insert(
          :goal,
          Map.merge(
            goal_literal(1),
            %{
              course: course,
              progress: [
                %{
                  count: 0,
                  completed: true,
                  course_reg_id: test_cr.id
                }
              ]
            }
          )
        )

      insert(:achievement, %{
        course: course,
        title: "Rune Master",
        is_task: true,
        is_variable_xp: false,
        position: 1,
        xp: 100,
        card_tile_url:
          "https://source-academy-assets.s3-ap-southeast-1.amazonaws.com/achievement/card-tile/rune-master-tile.png",
        goals: [
          %{goal_uuid: goal_complete.uuid},
          %{goal_uuid: goal_incomplete.uuid}
        ]
      })

      resp =
        Assessments.user_total_xp(
          course_id,
          user_id,
          course_reg_id
        )

      assert resp == 110
    end

    test "achievement, goal (no progress entry)", %{
      test_cr: test_cr,
      course_id: course_id,
      user_id: user_id,
      course_reg_id: course_reg_id
    } do
      course = test_cr.course

      assessment = insert(:assessment, %{is_published: true, course: course})
      question = insert(:question, %{assessment: assessment})

      submission =
        insert(:submission, %{
          assessment: assessment,
          student: test_cr,
          status: :submitted,
          xp_bonus: 100,
          is_grading_published: true
        })

      insert(:answer, %{
        question: question,
        submission: submission,
        xp: 20,
        xp_adjustment: -10
      })

      goal =
        insert(
          :goal,
          Map.merge(
            goal_literal(1),
            %{
              course: course
            }
          )
        )

      insert(:achievement, %{
        course: course,
        title: "Rune Master",
        is_task: true,
        is_variable_xp: false,
        position: 1,
        xp: 100,
        card_tile_url:
          "https://source-academy-assets.s3-ap-southeast-1.amazonaws.com/achievement/card-tile/rune-master-tile.png",
        goals: [
          %{goal_uuid: goal.uuid}
        ]
      })

      resp =
        Assessments.user_total_xp(
          course_id,
          user_id,
          course_reg_id
        )

      assert resp == 110
    end

    test "no assessments", %{
      test_cr: test_cr,
      course_id: course_id,
      user_id: user_id,
      course_reg_id: course_reg_id
    } do
      course = test_cr.course

      goal =
        insert(
          :goal,
          Map.merge(
            goal_literal(1),
            %{
              course: course,
              progress: [
                %{
                  count: 1,
                  completed: true,
                  course_reg_id: test_cr.id
                }
              ]
            }
          )
        )

      insert(:achievement, %{
        course: course,
        title: "Rune Master",
        is_task: true,
        is_variable_xp: false,
        position: 1,
        xp: 100,
        card_tile_url:
          "https://source-academy-assets.s3-ap-southeast-1.amazonaws.com/achievement/card-tile/rune-master-tile.png",
        goals: [
          %{goal_uuid: goal.uuid}
        ]
      })

      resp =
        Assessments.user_total_xp(
          course_id,
          user_id,
          course_reg_id
        )

      assert resp == 100
    end

    test "no achievements", %{
      test_cr: test_cr,
      course_id: course_id,
      user_id: user_id,
      course_reg_id: course_reg_id
    } do
      course = test_cr.course

      assessment = insert(:assessment, %{is_published: true, course: course})
      question = insert(:question, %{assessment: assessment})

      submission =
        insert(:submission, %{
          assessment: assessment,
          student: test_cr,
          status: :submitted,
          xp_bonus: 100,
          is_grading_published: true
        })

      insert(:answer, %{
        question: question,
        submission: submission,
        xp: 20,
        xp_adjustment: -10
      })

      resp =
        Assessments.user_total_xp(
          course_id,
          user_id,
          course_reg_id
        )

      assert resp == 110
    end

    test "achievement (is_variable_xp: true), no goals.", %{
      test_cr: test_cr,
      course_id: course_id,
      user_id: user_id,
      course_reg_id: course_reg_id
    } do
      course = test_cr.course

      assessment = insert(:assessment, %{is_published: true, course: course})
      question = insert(:question, %{assessment: assessment})

      submission =
        insert(:submission, %{
          assessment: assessment,
          student: test_cr,
          status: :submitted,
          xp_bonus: 100,
          is_grading_published: true
        })

      insert(:answer, %{
        question: question,
        submission: submission,
        xp: 20,
        xp_adjustment: -10
      })

      insert(:achievement, %{
        course: course,
        title: "Rune Master",
        is_task: true,
        is_variable_xp: true,
        position: 1,
        xp: 100,
        card_tile_url:
          "https://source-academy-assets.s3-ap-southeast-1.amazonaws.com/achievement/card-tile/rune-master-tile.png",
        goals: []
      })

      resp =
        Assessments.user_total_xp(
          course_id,
          user_id,
          course_reg_id
        )

      assert resp == 110
    end

    test "achievement (is_variable_xp: true), one incomplete goal (no progress entry).", %{
      test_cr: test_cr,
      course_id: course_id,
      user_id: user_id,
      course_reg_id: course_reg_id
    } do
      course = test_cr.course

      assessment = insert(:assessment, %{is_published: true, course: course})
      question = insert(:question, %{assessment: assessment})

      submission =
        insert(:submission, %{
          assessment: assessment,
          student: test_cr,
          status: :submitted,
          xp_bonus: 100,
          is_grading_published: true
        })

      insert(:answer, %{
        question: question,
        submission: submission,
        xp: 20,
        xp_adjustment: -10
      })

      goal =
        insert(
          :goal,
          Map.merge(
            goal_literal(1),
            %{
              course: course
            }
          )
        )

      insert(:achievement, %{
        course: course,
        title: "Rune Master",
        is_task: true,
        is_variable_xp: true,
        position: 1,
        xp: 100,
        card_tile_url:
          "https://source-academy-assets.s3-ap-southeast-1.amazonaws.com/achievement/card-tile/rune-master-tile.png",
        goals: [
          %{goal_uuid: goal.uuid}
        ]
      })

      resp =
        Assessments.user_total_xp(
          course_id,
          user_id,
          course_reg_id
        )

      assert resp == 110
    end

    test "achievement (is_variable_xp: true), one incomplete goal (with progress entry).", %{
      test_cr: test_cr,
      course_id: course_id,
      user_id: user_id,
      course_reg_id: course_reg_id
    } do
      course = test_cr.course

      assessment = insert(:assessment, %{is_published: true, course: course})
      question = insert(:question, %{assessment: assessment})

      submission =
        insert(:submission, %{
          assessment: assessment,
          student: test_cr,
          status: :submitted,
          xp_bonus: 100,
          is_grading_published: true
        })

      insert(:answer, %{
        question: question,
        submission: submission,
        xp: 20,
        xp_adjustment: -10
      })

      goal =
        insert(
          :goal,
          Map.merge(
            goal_literal(1),
            %{
              course: course,
              progress: [
                %{
                  count: 0,
                  completed: true,
                  course_reg_id: test_cr.id
                }
              ]
            }
          )
        )

      insert(:achievement, %{
        course: course,
        title: "Rune Master",
        is_task: true,
        is_variable_xp: true,
        position: 1,
        xp: 100,
        card_tile_url:
          "https://source-academy-assets.s3-ap-southeast-1.amazonaws.com/achievement/card-tile/rune-master-tile.png",
        goals: [
          %{goal_uuid: goal.uuid}
        ]
      })

      resp =
        Assessments.user_total_xp(
          course_id,
          user_id,
          course_reg_id
        )

      assert resp == 110
    end

    test "achievement (is_variable_xp: true), one goal completed.", %{
      test_cr: test_cr,
      course_id: course_id,
      user_id: user_id,
      course_reg_id: course_reg_id
    } do
      course = test_cr.course

      assessment = insert(:assessment, %{is_published: true, course: course})
      question = insert(:question, %{assessment: assessment})

      submission =
        insert(:submission, %{
          assessment: assessment,
          student: test_cr,
          status: :submitted,
          xp_bonus: 100,
          is_grading_published: true
        })

      insert(:answer, %{
        question: question,
        submission: submission,
        xp: 20,
        xp_adjustment: -10
      })

      goal =
        insert(
          :goal,
          Map.merge(
            goal_literal(1),
            %{
              course: course,
              progress: [
                %{
                  count: 1,
                  completed: true,
                  course_reg_id: test_cr.id
                }
              ]
            }
          )
        )

      insert(:achievement, %{
        course: course,
        title: "Rune Master",
        is_task: true,
        is_variable_xp: true,
        position: 1,
        xp: 100,
        card_tile_url:
          "https://source-academy-assets.s3-ap-southeast-1.amazonaws.com/achievement/card-tile/rune-master-tile.png",
        goals: [
          %{goal_uuid: goal.uuid}
        ]
      })

      resp =
        Assessments.user_total_xp(
          course_id,
          user_id,
          course_reg_id
        )

      assert resp == 111
    end

    test "achievement (is_variable_xp: true), with one goal completed and one goal incomplete", %{
      test_cr: test_cr,
      course_id: course_id,
      user_id: user_id,
      course_reg_id: course_reg_id
    } do
      course = test_cr.course

      assessment = insert(:assessment, %{is_published: true, course: course})
      question = insert(:question, %{assessment: assessment})

      submission =
        insert(:submission, %{
          assessment: assessment,
          student: test_cr,
          status: :submitted,
          xp_bonus: 100,
          is_grading_published: true
        })

      insert(:answer, %{
        question: question,
        submission: submission,
        xp: 20,
        xp_adjustment: -10
      })

      goal =
        insert(
          :goal,
          Map.merge(
            goal_literal(1),
            %{
              course: course,
              progress: [
                %{
                  count: 1,
                  completed: true,
                  course_reg_id: test_cr.id
                }
              ]
            }
          )
        )

      goal2 =
        insert(
          :goal,
          Map.merge(
            goal_literal(1),
            %{
              course: course,
              progress: [
                %{
                  count: 0,
                  completed: true,
                  course_reg_id: test_cr.id
                }
              ]
            }
          )
        )

      insert(:achievement, %{
        course: course,
        title: "Rune Master",
        is_task: true,
        is_variable_xp: true,
        position: 1,
        xp: 100,
        card_tile_url:
          "https://source-academy-assets.s3-ap-southeast-1.amazonaws.com/achievement/card-tile/rune-master-tile.png",
        goals: [
          %{goal_uuid: goal.uuid},
          %{goal_uuid: goal2.uuid}
        ]
      })

      resp =
        Assessments.user_total_xp(
          course_id,
          user_id,
          course_reg_id
        )

      assert resp == 110
    end

    test "achievement (is_variable_xp: true), one goal with 0 target_count and 0 count", %{
      test_cr: test_cr,
      course_id: course_id,
      user_id: user_id,
      course_reg_id: course_reg_id
    } do
      course = test_cr.course

      assessment = insert(:assessment, %{is_published: true, course: course})
      question = insert(:question, %{assessment: assessment})

      submission =
        insert(:submission, %{
          assessment: assessment,
          student: test_cr,
          status: :submitted,
          xp_bonus: 100,
          is_grading_published: true
        })

      insert(:answer, %{
        question: question,
        submission: submission,
        xp: 20,
        xp_adjustment: -10
      })

      goal =
        insert(
          :goal,
          Map.merge(
            goal_literal(0),
            %{
              course: course,
              progress: [
                %{
                  count: 0,
                  completed: true,
                  course_reg_id: test_cr.id
                }
              ]
            }
          )
        )

      insert(:achievement, %{
        course: course,
        title: "Rune Master",
        is_task: true,
        is_variable_xp: true,
        position: 1,
        xp: 100,
        card_tile_url:
          "https://source-academy-assets.s3-ap-southeast-1.amazonaws.com/achievement/card-tile/rune-master-tile.png",
        goals: [
          %{goal_uuid: goal.uuid}
        ]
      })

      resp =
        Assessments.user_total_xp(
          course_id,
          user_id,
          course_reg_id
        )

      assert resp == 110
    end
  end

  describe "grading published feature" do
    setup do
      course = insert(:course)
      config = insert(:assessment_config, %{type: "Test", course: course})
      student = insert(:course_registration, course: course, role: :student)
      student_2 = insert(:course_registration, course: course, role: :student)
      avenger = insert(:course_registration, course: course, role: :staff)

      assessment =
        insert(
          :assessment,
          open_at: Timex.shift(Timex.now(), hours: -1),
          close_at: Timex.shift(Timex.now(), hours: 500),
          is_published: true,
          config: config,
          course: course
        )

      question = insert(:mcq_question, assessment: assessment)

      submission =
        insert(:submission,
          assessment: assessment,
          student: student,
          status: :attempted,
          is_grading_published: false
        )

      _answer =
        insert(
          :answer,
          submission: submission,
          question: question,
          answer: %{:choice_id => 1},
          xp: 400,
          xp_adjustment: 300,
          comments: "Dummy Comment",
          autograding_status: :failed,
          autograding_results: [
            %{
              errors: [
                %{
                  error_message: "DummyError",
                  error_type: "systemError"
                }
              ],
              result_type: "error"
            }
          ],
          grader: avenger
        )

      published_submission =
        insert(:submission,
          assessment: assessment,
          student: student_2,
          status: :submitted,
          is_grading_published: true
        )

      _published_answer =
        insert(
          :answer,
          submission: published_submission,
          question: question,
          answer: %{:choice_id => 1},
          xp: 400,
          xp_adjustment: 300,
          comments: "Dummy Comment",
          autograding_status: :failed,
          autograding_results: [
            %{
              errors: [
                %{
                  error_message: "DummyError",
                  error_type: "systemError"
                }
              ],
              result_type: "error"
            }
          ],
          grader: avenger
        )

      %{assessment: assessment, student: student, student_2: student_2}
    end

    test "unpublished grades are hidden", %{assessment: assessment, student: student} do
      {_, assessment_with_q_and_a} =
        Assessments.assessment_with_questions_and_answers(assessment, student)

      formatted_assessment =
        Assessments.format_assessment_with_questions_and_answers(assessment_with_q_and_a)

      formatted_answer = hd(formatted_assessment.questions).answer

      assert formatted_answer.xp == 0
      assert formatted_answer.xp_adjustment == 0
      assert formatted_answer.autograding_status == :none
      assert formatted_answer.autograding_results == []
      assert formatted_answer.grader == nil
      assert formatted_answer.grader_id == nil
      assert formatted_answer.comments == nil
    end

    test "published grades are shown", %{assessment: assessment, student_2: student} do
      {_, assessment_with_q_and_a} =
        Assessments.assessment_with_questions_and_answers(assessment, student)

      formatted_assessment =
        Assessments.format_assessment_with_questions_and_answers(assessment_with_q_and_a)

      formatted_answer = hd(formatted_assessment.questions).answer

      assert formatted_answer.xp != 0
      assert formatted_answer.xp_adjustment != 0
      assert formatted_answer.autograding_status != :none
      assert formatted_answer.autograding_results != []
      assert formatted_answer.grader != nil
      assert formatted_answer.grader_id != nil
      assert formatted_answer.comments != nil
    end
  end

  describe "submissions_by_grader_for_index function" do
    setup do
      seed = Cadet.Test.Seeds.assessments()

      total_submissions =
        Integer.to_string(
          Enum.reduce(seed[:assessments], 0, fn {_, %{submissions: submissions}}, acc ->
            length(submissions) + acc
          end)
        )

      Map.put(seed, :total_submissions, total_submissions)
    end

    test "limit submissions", %{
      course_regs: %{avenger1_cr: avenger}
    } do
      {_, res} =
        Assessments.submissions_by_grader_for_index(avenger, %{
          :page_size => 1
        })

      assert length(res[:data][:submissions]) == 1
    end

    test "limit submisssions 2", %{
      course_regs: %{avenger1_cr: avenger},
      assessments: _assessments
    } do
      {_, res} =
        Assessments.submissions_by_grader_for_index(avenger, %{
          :page_size => 2
        })

      assert length(res[:data][:submissions]) == 2
    end

    test "filter by assessment title", %{
      course_regs: %{avenger1_cr: avenger},
      assessments: assessments,
      total_submissions: total_submissions
    } do
      assessment = assessments["mission"][:assessment]
      title = assessment.title

      {_, res} =
        Assessments.submissions_by_grader_for_index(avenger, %{
          :title => title,
          :page_size => total_submissions
        })

      assessments_from_res = res[:data][:assessments]

      Enum.each(assessments_from_res, fn a ->
        assert a.title == title
      end)
    end

    test "filter by submission status :attempting", %{
      course_regs: %{avenger1_cr: avenger},
      assessments: assessments,
      total_submissions: total_submissions
    } do
      expected_length =
        Enum.reduce(assessments, 0, fn {_, %{submissions: submissions}}, acc ->
          Enum.count(submissions, fn s -> s.status == :attempting end) + acc
        end)

      {_, res} =
        Assessments.submissions_by_grader_for_index(avenger, %{
          :status => "attempting",
          :page_size => total_submissions
        })

      submissions_from_res = res[:data][:submissions]

      assert length(submissions_from_res) == expected_length

      Enum.each(submissions_from_res, fn s ->
        assert s.status == :attempting
      end)
    end

    test "filter by submission status :attempted", %{
      course_regs: %{avenger1_cr: avenger},
      assessments: assessments,
      total_submissions: total_submissions
    } do
      expected_length =
        Enum.reduce(assessments, 0, fn {_, %{submissions: submissions}}, acc ->
          Enum.count(submissions, fn s -> s.status == :attempted end) + acc
        end)

      {_, res} =
        Assessments.submissions_by_grader_for_index(avenger, %{
          :status => "attempted",
          :page_size => total_submissions
        })

      submissions_from_res = res[:data][:submissions]

      assert length(submissions_from_res) == expected_length

      Enum.each(submissions_from_res, fn s ->
        assert s.status == :attempted
      end)
    end

    test "filter by submission status :submitted", %{
      course_regs: %{avenger1_cr: avenger},
      assessments: assessments,
      total_submissions: total_submissions
    } do
      expected_length =
        Enum.reduce(assessments, 0, fn {_, %{submissions: submissions}}, acc ->
          Enum.count(submissions, fn s -> s.status == :submitted end) + acc
        end)

      {_, res} =
        Assessments.submissions_by_grader_for_index(avenger, %{
          :status => "submitted",
          :page_size => total_submissions
        })

      submissions_from_res = res[:data][:submissions]

      assert length(submissions_from_res) == expected_length

      Enum.each(submissions_from_res, fn s ->
        assert s.status == :submitted
      end)
    end

    test "filter by submission fully graded", %{
      course_regs: %{avenger1_cr: avenger},
      assessments: assessments,
      total_submissions: total_submissions,
      students_with_assessment_info: students_with_assessment_info
    } do
      expected_length =
        length(Map.keys(assessments)) *
          Enum.count(students_with_assessment_info, fn {_, _, is_graded, _, _} -> is_graded end)

      {_, res} =
        Assessments.submissions_by_grader_for_index(avenger, %{
          :is_fully_graded => true,
          :page_size => total_submissions
        })

      submissions_from_res = res[:data][:submissions]

      assert length(submissions_from_res) == expected_length

      Enum.each(submissions_from_res, fn s ->
        assert s.question_count == s.graded_count
      end)
    end

    test "filter by submission not fully graded", %{
      course_regs: %{avenger1_cr: avenger},
      assessments: assessments,
      total_submissions: total_submissions,
      students_with_assessment_info: students_with_assessment_info
    } do
      expected_length =
        length(Map.keys(assessments)) *
          Enum.count(students_with_assessment_info, fn {_, _, is_graded, _, _} -> !is_graded end)

      {_, res} =
        Assessments.submissions_by_grader_for_index(avenger, %{
          :is_fully_graded => false,
          :page_size => total_submissions
        })

      submissions_from_res = res[:data][:submissions]

      assert length(submissions_from_res) == expected_length

      Enum.each(submissions_from_res, fn s ->
        assert s.question_count > s.graded_count
      end)
    end

    test "filter by submission published", %{
      course_regs: %{avenger1_cr: avenger},
      assessments: assessments,
      total_submissions: total_submissions,
      students_with_assessment_info: students_with_assessment_info
    } do
      expected_length =
        length(Map.keys(assessments)) *
          Enum.count(students_with_assessment_info, fn {_, _, _, is_published, _} ->
            is_published
          end)

      {_, res} =
        Assessments.submissions_by_grader_for_index(avenger, %{
          :is_grading_published => true,
          :page_size => total_submissions
        })

      submissions_from_res = res[:data][:submissions]

      assert length(submissions_from_res) == expected_length

      Enum.each(submissions_from_res, fn s ->
        assert s.is_grading_published == true
      end)
    end

    test "filter by submission not published", %{
      course_regs: %{avenger1_cr: avenger},
      assessments: assessments,
      total_submissions: total_submissions,
      students_with_assessment_info: students_with_assessment_info
    } do
      expected_length =
        length(Map.keys(assessments)) *
          Enum.count(students_with_assessment_info, fn {_, _, _, is_published, _} ->
            !is_published
          end)

      {_, res} =
        Assessments.submissions_by_grader_for_index(avenger, %{
          :is_grading_published => false,
          :page_size => total_submissions
        })

      submissions_from_res = res[:data][:submissions]

      assert length(submissions_from_res) == expected_length

      Enum.each(submissions_from_res, fn s ->
        assert s.is_grading_published == false
      end)
    end

    test "filter by group avenger", %{
      course_regs: %{avenger1_cr: avenger, group: group, students: students},
      assessments: assessments,
      total_submissions: total_submissions,
      students_with_assessment_info: students_with_assessment_info
    } do
      expected_length =
        length(Map.keys(assessments)) *
          Enum.count(students_with_assessment_info, fn {_, _, _, _, avenger_cr} ->
            avenger_cr.id == avenger.id
          end)

      {_, res} =
        Assessments.submissions_by_grader_for_index(avenger, %{
          :group => true,
          :page_size => total_submissions
        })

      submissions_from_res = res[:data][:submissions]

      assert length(submissions_from_res) == expected_length

      Enum.each(submissions_from_res, fn s ->
        student = Enum.find(students, fn student -> student.id == s.student_id end)
        assert student.group.id == group.id
      end)
    end

    test "filter by group avenger2", %{
      course_regs: %{avenger2_cr: avenger2, group2: group2, students: students},
      assessments: assessments,
      total_submissions: total_submissions,
      students_with_assessment_info: students_with_assessment_info
    } do
      expected_length =
        length(Map.keys(assessments)) *
          Enum.count(students_with_assessment_info, fn {_, _, _, _, avenger_cr} ->
            avenger_cr.id == avenger2.id
          end)

      {_, res} =
        Assessments.submissions_by_grader_for_index(avenger2, %{
          :group => true,
          :page_size => total_submissions
        })

      submissions_from_res = res[:data][:submissions]

      assert length(submissions_from_res) == expected_length

      Enum.each(submissions_from_res, fn s ->
        student = Enum.find(students, fn student -> student.id == s.student_id end)
        assert student.group.id == group2.id
      end)
    end

    # Chose avenger2 to ensure that the group name is not the same as the avenger's group
    test "filter by group name group", %{
      course_regs: %{avenger2_cr: avenger2, group: group, students: students},
      assessments: assessments,
      total_submissions: total_submissions,
      students_with_assessment_info: students_with_assessment_info
    } do
      expected_length =
        length(Map.keys(assessments)) *
          Enum.count(students_with_assessment_info, fn {student, _, _, _, _} ->
            student.group.id == group.id
          end)

      group_name = group.name

      {_, res} =
        Assessments.submissions_by_grader_for_index(avenger2, %{
          :group_name => group_name,
          :page_size => total_submissions
        })

      submissions_from_res = res[:data][:submissions]

      assert length(submissions_from_res) == expected_length

      Enum.each(submissions_from_res, fn s ->
        student = Enum.find(students, fn student -> student.id == s.student_id end)
        assert student.group.id == group.id
      end)
    end

    # Chose avenger to ensure that the group name is not the same as the avenger's group
    test "filter by group name group2", %{
      course_regs: %{avenger1_cr: avenger, group2: group2, students: students},
      assessments: assessments,
      total_submissions: total_submissions,
      students_with_assessment_info: students_with_assessment_info
    } do
      expected_length =
        length(Map.keys(assessments)) *
          Enum.count(students_with_assessment_info, fn {student, _, _, _, _} ->
            student.group.id == group2.id
          end)

      group_name = group2.name

      {_, res} =
        Assessments.submissions_by_grader_for_index(avenger, %{
          :group_name => group_name,
          :page_size => total_submissions
        })

      submissions_from_res = res[:data][:submissions]

      assert length(submissions_from_res) == expected_length

      Enum.each(submissions_from_res, fn s ->
        student = Enum.find(students, fn student -> student.id == s.student_id end)
        assert student.group.id == group2.id
      end)
    end

    test "filter by student name", %{
      course_regs: %{avenger1_cr: avenger, students: students},
      assessments: assessments,
      total_submissions: total_submissions
    } do
      expected_length = length(Map.keys(assessments))
      student = Enum.at(students, 0)
      student_name = student.user.name

      {_, res} =
        Assessments.submissions_by_grader_for_index(avenger, %{
          :name => student_name,
          :page_size => total_submissions
        })

      submissions_from_res = res[:data][:submissions]

      assert length(submissions_from_res) == expected_length

      Enum.each(submissions_from_res, fn s ->
        assert s.student_id == student.id
      end)
    end

    test "filter by student name 2", %{
      course_regs: %{avenger1_cr: avenger, students: students},
      assessments: assessments,
      total_submissions: total_submissions
    } do
      expected_length = length(Map.keys(assessments))
      student = Enum.at(students, 1)
      student_name = student.user.name

      {_, res} =
        Assessments.submissions_by_grader_for_index(avenger, %{
          :name => student_name,
          :page_size => total_submissions
        })

      submissions_from_res = res[:data][:submissions]

      assert length(submissions_from_res) == expected_length

      Enum.each(submissions_from_res, fn s ->
        assert s.student_id == student.id
      end)
    end

    test "filter by student name 3", %{
      course_regs: %{avenger1_cr: avenger, students: students},
      assessments: assessments,
      total_submissions: total_submissions
    } do
      expected_length = length(Map.keys(assessments))
      student = Enum.at(students, 2)
      student_name = student.user.name

      {_, res} =
        Assessments.submissions_by_grader_for_index(avenger, %{
          :name => student_name,
          :page_size => total_submissions
        })

      submissions_from_res = res[:data][:submissions]

      assert length(submissions_from_res) == expected_length

      Enum.each(submissions_from_res, fn s ->
        assert s.student_id == student.id
      end)
    end

    test "filter by student username 1", %{
      course_regs: %{avenger1_cr: avenger, students: students},
      assessments: assessments,
      total_submissions: total_submissions
    } do
      expected_length = length(Map.keys(assessments))
      student = Enum.at(students, 0)
      student_username = student.user.username

      {_, res} =
        Assessments.submissions_by_grader_for_index(avenger, %{
          :username => student_username,
          :page_size => total_submissions
        })

      submissions_from_res = res[:data][:submissions]

      assert length(submissions_from_res) == expected_length

      Enum.each(submissions_from_res, fn s ->
        assert s.student_id == student.id
      end)
    end

    test "filter by student username 2", %{
      course_regs: %{avenger1_cr: avenger, students: students},
      assessments: assessments,
      total_submissions: total_submissions
    } do
      expected_length = length(Map.keys(assessments))
      student = Enum.at(students, 1)
      student_username = student.user.username

      {_, res} =
        Assessments.submissions_by_grader_for_index(avenger, %{
          :username => student_username,
          :page_size => total_submissions
        })

      submissions_from_res = res[:data][:submissions]

      assert length(submissions_from_res) == expected_length

      Enum.each(submissions_from_res, fn s ->
        assert s.student_id == student.id
      end)
    end

    test "filter by student username 3", %{
      course_regs: %{avenger1_cr: avenger, students: students},
      assessments: assessments,
      total_submissions: total_submissions
    } do
      expected_length = length(Map.keys(assessments))
      student = Enum.at(students, 2)
      student_username = student.user.username

      {_, res} =
        Assessments.submissions_by_grader_for_index(avenger, %{
          :username => student_username,
          :page_size => total_submissions
        })

      submissions_from_res = res[:data][:submissions]

      assert length(submissions_from_res) == expected_length

      Enum.each(submissions_from_res, fn s ->
        assert s.student_id == student.id
      end)
    end

    test "filter by assessment config 1", %{
      course_regs: %{avenger1_cr: avenger, students: students},
      assessment_configs: assessment_configs,
      total_submissions: total_submissions
    } do
      expected_length = 1 * length(students)
      assessment_config = Enum.at(assessment_configs, 0)
      assessment_type = assessment_config.type

      {_, res} =
        Assessments.submissions_by_grader_for_index(avenger, %{
          :type => assessment_type,
          :page_size => total_submissions
        })

      assessments_from_res = res[:data][:assessments]
      submissions_from_res = res[:data][:submissions]
      assessment = Enum.at(assessments_from_res, 0)
      assessment_id = assessment.id

      assert length(assessments_from_res) == 1
      assert length(submissions_from_res) == expected_length

      Enum.each(submissions_from_res, fn s ->
        assert s.assessment_id == assessment_id
      end)
    end

    test "filter by assessment config 2", %{
      course_regs: %{avenger1_cr: avenger, students: students},
      assessment_configs: assessment_configs,
      total_submissions: total_submissions
    } do
      expected_length = 1 * length(students)

      assessment_config = Enum.at(assessment_configs, 1)
      assessment_type = assessment_config.type

      {_, res} =
        Assessments.submissions_by_grader_for_index(avenger, %{
          :type => assessment_type,
          :page_size => total_submissions
        })

      assessments_from_res = res[:data][:assessments]
      submissions_from_res = res[:data][:submissions]
      assessment = Enum.at(assessments_from_res, 0)
      assessment_id = assessment.id

      assert length(assessments_from_res) == 1
      assert length(submissions_from_res) == expected_length

      Enum.each(submissions_from_res, fn s ->
        assert s.assessment_id == assessment_id
      end)
    end

    test "filter by assessment config 3", %{
      course_regs: %{avenger1_cr: avenger, students: students},
      assessment_configs: assessment_configs,
      total_submissions: total_submissions
    } do
      expected_length = 1 * length(students)

      assessment_config = Enum.at(assessment_configs, 2)
      assessment_type = assessment_config.type

      {_, res} =
        Assessments.submissions_by_grader_for_index(avenger, %{
          :type => assessment_type,
          :page_size => total_submissions
        })

      assessments_from_res = res[:data][:assessments]
      submissions_from_res = res[:data][:submissions]
      assessment = Enum.at(assessments_from_res, 0)
      assessment_id = assessment.id

      assert length(assessments_from_res) == 1
      assert length(submissions_from_res) == expected_length

      Enum.each(submissions_from_res, fn s ->
        assert s.assessment_id == assessment_id
      end)
    end

    test "filter by assessment config manually graded", %{
      course_regs: %{avenger1_cr: avenger, students: students},
      assessment_configs: assessment_configs,
      total_submissions: total_submissions
    } do
      expected_length =
        Enum.reduce(assessment_configs, 0, fn config, acc ->
          if config.is_manually_graded, do: acc + 1, else: acc
        end) * length(students)

      {_, res} =
        Assessments.submissions_by_grader_for_index(avenger, %{
          :is_manually_graded => true,
          :page_size => total_submissions
        })

      submissions_from_res = res[:data][:submissions]
      assessments_from_res = res[:data][:assessments]
      assessment_configs_from_res = Enum.map(assessments_from_res, fn a -> a.config end)

      assert length(submissions_from_res) == expected_length
      Enum.each(assessment_configs_from_res, fn config -> assert config.is_manually_graded end)

      # We know all assessments_from_res have correct config from previous check
      Enum.each(submissions_from_res, fn s ->
        assert Enum.find(assessments_from_res, fn a -> a.id == s.assessment_id end) != nil
      end)
    end

    test "filter by assessment config not manually graded", %{
      course_regs: %{avenger1_cr: avenger, students: students},
      assessment_configs: assessment_configs,
      total_submissions: total_submissions
    } do
      expected_length =
        Enum.reduce(assessment_configs, 0, fn config, acc ->
          if config.is_manually_graded, do: acc, else: acc + 1
        end) * length(students)

      {_, res} =
        Assessments.submissions_by_grader_for_index(avenger, %{
          :is_manually_graded => false,
          :page_size => total_submissions
        })

      submissions_from_res = res[:data][:submissions]
      assessments_from_res = res[:data][:assessments]
      assessment_configs_from_res = Enum.map(assessments_from_res, fn a -> a.config end)

      assert length(submissions_from_res) == expected_length
      Enum.each(assessment_configs_from_res, fn config -> assert !config.is_manually_graded end)

      # We know all assessments_from_res have correct config from previous check
      Enum.each(submissions_from_res, fn s ->
        assert Enum.find(assessments_from_res, fn a -> a.id == s.assessment_id end) != nil
      end)
    end

    test "sorting by assessment title ascending", %{
      course_regs: %{avenger1_cr: avenger},
      assessments: _assessments,
      total_submissions: total_submissions
    } do
      {_, res} =
        Assessments.submissions_by_grader_for_index(avenger, %{
          :page_size => total_submissions,
          :sort_by => :assessment_name,
          :sort_direction => :asc
        })

      submissions_from_res = res[:data][:submissions]
      assessments_from_res = res[:data][:assessments]

      submissions_by_title =
        Enum.map(
          submissions_from_res,
          fn s ->
            Enum.find(assessments_from_res, fn a ->
              s.assessment_id == a.id
            end)
          end
        )

      Enum.reduce(
        submissions_by_title,
        fn x, y ->
          assert x.title >= y.title
          y
        end
      )
    end

    test "sorting by assessment title descending", %{
      course_regs: %{avenger1_cr: avenger},
      assessments: _assessments,
      total_submissions: total_submissions
    } do
      {_, res} =
        Assessments.submissions_by_grader_for_index(avenger, %{
          :page_size => total_submissions,
          :sort_by => :assessment_name,
          :sort_direction => :desc
        })

      submissions_from_res = res[:data][:submissions]
      assessments_from_res = res[:data][:assessments]

      submissions_by_title =
        Enum.map(
          submissions_from_res,
          fn s ->
            Enum.find(assessments_from_res, fn a ->
              s.assessment_id == a.id
            end)
          end
        )

      Enum.reduce(
        submissions_by_title,
        fn x, y ->
          assert x.title <= y.title
          y
        end
      )
    end

    test "sorting by assessment type ascending", %{
      course_regs: %{avenger1_cr: avenger},
      assessments: _assessments,
      total_submissions: total_submissions
    } do
      {_, res} =
        Assessments.submissions_by_grader_for_index(avenger, %{
          :page_size => total_submissions,
          :sort_by => :assessment_type,
          :sort_direction => :asc
        })

      submissions_from_res = res[:data][:submissions]
      assessments_from_res = res[:data][:assessments]

      submissions_by_assessments_type =
        Enum.map(
          submissions_from_res,
          fn s ->
            Enum.find(assessments_from_res, fn a ->
              s.assessment_id == a.id
            end)
          end
        )

      Enum.reduce(
        submissions_by_assessments_type,
        fn x, y ->
          assert x.config_id >= y.config_id
          y
        end
      )
    end

    test "sorting by assessment type descending", %{
      course_regs: %{avenger1_cr: avenger},
      assessments: _assessments,
      total_submissions: total_submissions
    } do
      {_, res} =
        Assessments.submissions_by_grader_for_index(avenger, %{
          :page_size => total_submissions,
          :sort_by => :assessment_type,
          :sort_direction => :desc
        })

      submissions_from_res = res[:data][:submissions]
      assessments_from_res = res[:data][:assessments]

      submissions_by_assessments_type =
        Enum.map(
          submissions_from_res,
          fn s ->
            Enum.find(assessments_from_res, fn a ->
              s.assessment_id == a.id
            end)
          end
        )

      Enum.reduce(
        submissions_by_assessments_type,
        fn x, y ->
          assert x.config_id <= y.config_id
          y
        end
      )
    end

    test "sorting by xp ascending", %{
      course_regs: %{avenger1_cr: avenger},
      assessments: _assessments,
      total_submissions: total_submissions
    } do
      {_, res} =
        Assessments.submissions_by_grader_for_index(avenger, %{
          :page_size => total_submissions,
          :sort_by => :xp,
          :sort_direction => :asc
        })

      submissions_from_res = res[:data][:submissions]

      Enum.reduce(
        submissions_from_res,
        fn x, y ->
          assert x.xp >= y.xp
          y
        end
      )
    end

    test "sorting by xp descending", %{
      course_regs: %{avenger1_cr: avenger},
      assessments: _assessments,
      total_submissions: total_submissions
    } do
      {_, res} =
        Assessments.submissions_by_grader_for_index(avenger, %{
          :page_size => total_submissions,
          :sort_by => :xp,
          :sort_direction => :desc
        })

      submissions_from_res = res[:data][:submissions]

      Enum.reduce(
        submissions_from_res,
        fn x, y ->
          assert x.xp <= y.xp
          y
        end
      )
    end
  end

  describe "is_fully_autograded? function" do
    setup do
      assessment = insert(:assessment)
      student = insert(:course_registration, role: :student)
      question = insert(:mcq_question, assessment: assessment)
      question2 = insert(:mcq_question, assessment: assessment)

      submission =
        insert(:submission, assessment: assessment, student: student, status: :submitted)

      %{question: question, question2: question2, submission: submission}
    end

    test "returns true when all answers are autograded successfully", %{
      question: question,
      question2: question2,
      submission: submission
    } do
      insert(:answer, submission: submission, question: question, autograding_status: :success)
      insert(:answer, submission: submission, question: question2, autograding_status: :success)

      assert Assessments.is_fully_autograded?(submission.id) == true
    end

    test "returns false when not all answers are autograded successfully", %{
      question: question,
      question2: question2,
      submission: submission
    } do
      insert(:answer, submission: submission, question: question, autograding_status: :success)
      insert(:answer, submission: submission, question: question2, autograding_status: :failed)

      assert Assessments.is_fully_autograded?(submission.id) == false
    end

    test "returns false when not all answers are autograded successfully 2", %{
      question: question,
      question2: question2,
      submission: submission
    } do
      insert(:answer, submission: submission, question: question, autograding_status: :success)
      insert(:answer, submission: submission, question: question2, autograding_status: :none)

      assert Assessments.is_fully_autograded?(submission.id) == false
    end
  end

  describe "publish and unpublish all grading" do
    setup do
      Cadet.Test.Seeds.assessments()
    end

    test "publish all graded submissions for an assessment",
         %{
           role_crs: %{admin: admin},
           assessments: assessments,
           students_with_assessment_info: students
         } do
      assessment_id = assessments["mission"][:assessment].id

      # 1 student has all assessments published
      expected_length =
        Enum.count(students, fn {_, _, is_graded, is_grading_published, _} ->
          is_graded and not is_grading_published
        end) + length(Map.keys(assessments))

      Assessments.publish_all_graded(admin, assessment_id)

      published_submissions =
        Submission
        |> where([s], s.is_grading_published == true)
        |> select([s], %{count: s.id |> count()})
        |> Repo.one()

      number_of_published_submissions = published_submissions.count
      assert number_of_published_submissions == expected_length
    end

    test "unpublish all submissions for an assessment",
         %{
           role_crs: %{admin: admin},
           assessments: assessments,
           students_with_assessment_info: students
         } do
      assessment_id = assessments["mission"][:assessment].id

      published_submissions_before =
        Submission
        |> where([s], s.is_grading_published == true)
        |> select([s], %{count: s.id |> count()})
        |> Repo.one()

      expected_unpublished_length =
        Enum.count(students, fn {_, _, _, is_grading_published, _} ->
          is_grading_published
        end)

      Assessments.unpublish_all(admin, assessment_id)

      published_submissions_after =
        Submission
        |> where([s], s.is_grading_published == true)
        |> select([s], %{count: s.id |> count()})
        |> Repo.one()

      assert published_submissions_after.count + expected_unpublished_length ==
               published_submissions_before.count
    end
  end

  describe "all_user_total_xp pagination with offset and limit" do
    setup do
      course = insert(:course)
      config = insert(:assessment_config)

      # generate question to award xp
      assessment = insert(:assessment, %{course: course, config: config})
      question = insert(:programming_question, assessment: assessment)

      # generate 50 students
      student_list = insert_list(50, :course_registration, %{course: course, role: :student})

      # generate submission for each student
      submission_list =
        Enum.map(
          student_list,
          fn student ->
            insert(
              :submission,
              student: student,
              assessment: assessment,
              status: "submitted",
              is_grading_published: true
            )
          end
        )

      # generate answer for each student with xp
      random_perm = Enum.shuffle(1..50)

      _ans_list =
        Enum.map(
          Enum.with_index(submission_list),
          fn {submission, index} ->
            insert(
              :answer,
              answer: build(:programming_answer),
              submission: submission,
              question: question,
              xp: Enum.at(random_perm, index)
            )
          end
        )

      %{course: course}
    end

    test "correctly fetches all students with their xp in descending order", %{course: course} do
      all_user_xp = Assessments.all_user_total_xp(course.id)
      assert get_all_student_xp(all_user_xp) == 50..1 |> Enum.to_list()
    end

    test "correctly fetches only relevant students for leaderboard display with potential overflow",
         %{course: course} do
      Enum.each(1..50, fn x ->
        offset = Enum.random(0..49)
        limit = Enum.random(1..50)

        paginated_user_xp =
          Assessments.all_user_total_xp(course.id, %{offset: offset, limit: limit})

        expected_xp_list =
          50..1
          |> Enum.to_list()
          |> Enum.slice(offset, limit)

        assert get_all_student_xp(paginated_user_xp) == expected_xp_list
      end)
    end
  end

  describe "automatic xp assignment for contest winners function" do
    setup do
      course = insert(:course)
      config = insert(:assessment_config)

      contest_assessment = insert(:assessment, %{course: course, config: config})
      contest_question = insert(:programming_question, assessment: contest_assessment)
      voting_assessment = insert(:assessment, %{course: course, config: config})
      voting_question = insert(:voting_question, assessment: voting_assessment)

      # generate 5 students
      student_list = insert_list(5, :course_registration, %{course: course, role: :student})

      # generate contest submission for each student
      submission_list =
        Enum.map(
          student_list,
          fn student ->
            insert(
              :submission,
              student: student,
              assessment: contest_assessment,
              status: "submitted"
            )
          end
        )

      # generate answer for each student
      ans_list =
        Enum.map(
          Enum.with_index(submission_list),
          fn {submission, index} ->
            insert(
              :answer,
              answer: build(:programming_answer),
              submission: submission,
              question: contest_question,
              popular_score: index,
              relative_score: 10 - index,
              xp: 100
            )
          end
        )

      # generate submission votes for each student
      _submission_votes =
        Enum.map(
          student_list,
          fn student ->
            Enum.map(
              Enum.with_index(submission_list),
              fn {submission, index} ->
                insert(
                  :submission_vote,
                  voter: student,
                  submission: submission,
                  question: voting_question
                )
              end
            )
          end
        )

      %{
        course: course,
        voting_question: voting_question,
        ans_list: ans_list
      }
    end

    test "correctly assigns xp to winning contest entries with default xp values", %{
      course: course,
      voting_question: voting_question,
      ans_list: _ans_list
    } do
      # verify that xp is adjusted correctly
      Assessments.assign_winning_contest_entries_xp(voting_question.id)
      all_user_xp = Assessments.all_user_total_xp(course.id)
      assert get_all_student_xp(all_user_xp) == [700, 600, 600, 500, 500]
    end

    test "correctly reassigns xp to winning contest entries upon mutliple calls", %{
      course: course,
      voting_question: voting_question,
      ans_list: ans_list
    } do
      # reset scores to 0
      Answer
      |> Repo.update_all(set: [popular_score: 0, relative_score: 0, xp: 0])

      # assign rank 1 xp to all students
      Assessments.assign_winning_contest_entries_xp(voting_question.id)
      all_user_xp = Assessments.all_user_total_xp(course.id)
      assert get_all_student_xp(all_user_xp) == [1000, 1000, 1000, 1000, 1000]

      # reassign scores and xp
      ans_list
      |> Enum.with_index()
      |> Enum.each(fn {answer, index} ->
        Answer
        |> where([a], a.id == ^answer.id)
        |> Repo.update_all(
          set: [
            popular_score: index,
            relative_score: 10 - index
          ]
        )
      end)

      # verify that xp is assigned correctly
      Assessments.assign_winning_contest_entries_xp(voting_question.id)
      all_user_xp = Assessments.all_user_total_xp(course.id)
      assert get_all_student_xp(all_user_xp) == [600, 500, 500, 400, 400]
    end

    test "correctly assigns xp to tied winning contest entries", %{
      course: course,
      voting_question: voting_question,
      ans_list: ans_list
    } do
      # assign tied scores
      # score_rank = [3, 3, 3, 1, 1]
      # popular_rank = [1, 1, 3, 3, 3]
      ans_list
      |> Enum.with_index()
      |> Enum.each(fn {answer, index} ->
        p_score = if index <= 1, do: 1, else: 0
        r_score = if index >= 3, do: 1, else: 0

        Answer
        |> where([a], a.id == ^answer.id)
        |> Repo.update_all(
          set: [
            popular_score: p_score,
            relative_score: r_score
          ]
        )
      end)

      # verify that xp is assigned correctly to tied entries
      Assessments.assign_winning_contest_entries_xp(voting_question.id)
      all_user_xp = Assessments.all_user_total_xp(course.id)
      assert get_all_student_xp(all_user_xp) == [900, 900, 900, 900, 700]
    end

    test "correctly assigns xp to winning contest entries with defined xp values", %{
      course: course,
      voting_question: voting_question,
      ans_list: ans_list
    } do
      # update defined xp_values for voting question
      Question
      |> where([q], q.id == ^voting_question.id)
      |> Repo.update_all(
        set: [
          question: Map.merge(voting_question.question, %{xp_values: [50, 40, 30, 20, 10]})
        ]
      )

      # verify that xp is assigned correctly with predefined xp_values
      Assessments.assign_winning_contest_entries_xp(voting_question.id)
      all_user_xp = Assessments.all_user_total_xp(course.id)
      assert get_all_student_xp(all_user_xp) == List.duplicate(160, 5)
    end
  end

  defp get_answer_relative_scores(answers) do
    answers |> Enum.map(fn ans -> ans.relative_score end)
  end

  defp get_question_ids(questions) do
    questions |> Enum.map(fn q -> q.id end) |> Enum.sort()
  end

  defp expected_top_relative_scores(top_x, token_divider) do
    # "return 0;" in the factory has 3 token
    10..0//-1
    |> Enum.to_list()
    |> Enum.map(fn score -> 10 * score - :math.pow(2, 3 / token_divider) end)
    |> Enum.take(top_x)
  end

  defp get_all_student_xp(all_users) do
    all_users.users
    |> Enum.map(fn user -> user.total_xp end)
  end
end
