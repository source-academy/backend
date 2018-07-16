defmodule Cadet.Factory do
  @moduledoc """
  Factory for testing
  """
  use ExMachina.Ecto, repo: Cadet.Repo
  # fields_for has been deprecated, only raising exception
  @dialyzer {:no_return, fields_for: 1}

  alias Cadet.Assessments.{Answer, Assessment, Question, Submission}
  alias Cadet.Course.{Announcement, Group, Material}

  use Cadet.Accounts.{AuthorizationFactory, UserFactory}
  use Cadet.Course.{AnnouncementFactory, GroupFactory, MaterialFactory}

  def upload_factory do
    %Plug.Upload{
      content_type: "text/plain",
      filename: sequence(:upload, &"upload#{&1}.txt"),
      path: "test/fixtures/upload.txt"
    }
  end

  def assessment_factory do
    %Assessment{
      title: Faker.Lorem.Shakespeare.En.hamlet(),
      summary_short: Faker.Lorem.Shakespeare.En.king_richard_iii(),
      summary_long: Faker.Lorem.Shakespeare.En.romeo_and_juliet(),
      type: Enum.random([:mission, :sidequest, :contest, :path]),
      open_at: Timex.now(),
      close_at: Timex.shift(Timex.now(), days: Enum.random(1..30)),
      is_published: false
    }
  end

  def submission_factory do
    %Submission{
      student: build(:user, %{role: :student}),
      assessment: build(:assessment)
    }
  end

  def question_factory do
    %Question{
      title: sequence("question"),
      question: %{},
      type: Enum.random([:programming, :multiple_choice]),
      assessment: build(:assessment, %{is_published: true})
    }
  end

  def programming_question_factory do
    %{
      content: Faker.Pokemon.name(),
      solution_header: Faker.Pokemon.location(),
      solution_template: Faker.Lorem.Shakespeare.as_you_like_it(),
      solution: Faker.Lorem.Shakespeare.hamlet()
    }
  end

  def mcq_question_factory do
    %{
      content: Faker.Pokemon.name(),
      choices: Enum.map(0..2, &build(:mcq_choice, %{choice_id: &1, is_correct: &1 == 0}))
    }
  end

  def mcq_choice_factory do
    %{
      content: Faker.Pokemon.name(),
      hint: Faker.Pokemon.location()
    }
  end

  def answer_factory do
    %Answer{
      answer: %{}
    }
  end

  def programming_answer_factory do
    %{
      code: sequence(:code, &"alert(#{&1})")
    }
  end

  def mcq_answer_factory do
    %{
      choice_id: Enum.random(0..2)
    }
  end

  def library_factory do
    %{
      chapter: Enum.random(1..20),
      globals: Faker.Lorem.words(Enum.random(1..3)),
      externals: Faker.Lorem.words(Enum.random(1..3)),
      files: (&Faker.File.file_name/0) |> Stream.repeatedly() |> Enum.take(5)
    }
  end
end
