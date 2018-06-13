defmodule Cadet.Factory do
  @moduledoc """
  Factory for testing
  """
  use ExMachina.Ecto, repo: Cadet.Repo
  # fields_for has been deprecated, only raising exception
  @dialyzer {:no_return, fields_for: 1}

  alias Cadet.Accounts.User
  alias Cadet.Accounts.Authorization
  alias Cadet.Course.Announcement
  alias Cadet.Course.Point
  alias Cadet.Course.Group
  alias Cadet.Course.Material
  alias Cadet.Assessments.Mission
  alias Cadet.Assessments.Question

  def user_factory do
    %User{
      first_name: "John Smith",
      role: :student
    }
  end

  def email_factory do
    %Authorization{
      provider: :email,
      uid: sequence(:email, &"email-#{&1}@example.com"),
      token: sequence(:token, &"token-#{&1}"),
      user: build(:user)
    }
  end

  def announcement_factory do
    %Announcement{
      title: sequence(:title, &"Announcement #{&1}"),
      content: "Some content",
      poster: build(:user)
    }
  end

  def point_factory do
    %Point{
      reason: "Dummy reason",
      amount: 100,
      given_by: build(:user, %{role: :staff}),
      given_to: build(:user)
    }
  end

  def group_factory do
    %Group{
      leader: build(:user, %{role: :staff}),
      student: build(:user, %{role: :student})
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

  def mission_factory do
    %Mission{
      title: "mission",
      category: Enum.random([:mission, :sidequest, :contest, :path]),
      open_at: Timex.now(),
      close_at: Timex.shift(Timex.now(), days: Enum.random(1..30))
    }
  end

  def question_factory do
    %Question{
      title: "question",
      weight: Enum.random(1..10),
      question: %{},
      type: Enum.random([:programming, :multiple_choice]),
      mission: build(:mission)
    }
  end
end
