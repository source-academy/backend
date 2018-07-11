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
      name: "John Smith",
      role: :staff
    }
  end

  def student_factory do
    %User{
      name: sequence("student"),
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
      name: sequence("group")
    }
  end

  def announcement_factory do
    %Announcement{
      title: sequence(:title, &"Announcement #{&1}"),
      content: "Some content",
      poster: build(:user)
    }
  end

  def material_folder_factory do
    %Material{
      name: "Folder",
      description: "This is a folder",
      uploader: build(:user, %{role: :staff})
    }
  end

  def material_file_factory do
    %Material{
      name: "Folder",
      description: "This is a folder",
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
      title: "assessment",
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
      content: sequence("ProgrammingQuestion"),
      solution_template: "f => f(f);",
      solution: "(f => f(f))(f => f(f));"
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

  def submission_factory do
    %Submission{}
  end
end
