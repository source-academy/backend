defmodule Cadet.Factory do
  @moduledoc """
  Factory for testing
  """
  use ExMachina.Ecto, repo: Cadet.Repo
  # fields_for has been deprecated, only raising exception
  @dialyzer {:no_return, fields_for: 1}

  alias Cadet.Accounts.{Authorization, User}
  alias Cadet.Assessments.{Answer, Assessment, Question, Submission}
  alias Cadet.Course.{Announcement, Group, Material}

  def user_factory do
    %User{
      name: Faker.Name.En.name(),
      role: :staff
    }
  end

  def student_factory do
    %User{
      name: Faker.Name.En.name(),
      role: :student
    }
  end

  def nusnet_id_factory do
    %Authorization{
      provider: :nusnet_id,
      uid: sequence(:nusnet_id, &"E#{&1}"),
      user: build(:user)
    }
  end

  def group_factory do
    %Group{
      name: Faker.Company.name()
    }
  end

  def announcement_factory do
    %Announcement{
      title: sequence(:title, &"Announcement #{&1}") <> Faker.Company.catch_phrase(),
      content: Faker.StarWars.quote(),
      poster: build(:user)
    }
  end

  def material_folder_factory do
    %Material{
      name: Faker.Cat.name(),
      description: Faker.Cat.breed(),
      uploader: build(:user, %{role: :staff})
    }
  end

  def material_file_factory do
    %Material{
      name: Faker.StarWars.character(),
      description: Faker.StarWars.planet(),
      file: build(:upload),
      parent: build(:material_folder),
      uploader: build(:user, %{role: :staff})
    }
  end

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
      solution_template: "f => f(f);",
      solution: "(f => f(f))(f => f(f));"
    }
  end

  def mcq_question_factory do
    %{
      content: Faker.Pokemon.name(),
      choices:
        Enum.map(0..2, fn x ->
          build(:mcq_choice, %{choice_id: x, is_correct: x == 0})
        end)
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
      files: Enum.map(1..5, fn _ -> Faker.File.file_name() end)
    }
  end
end
