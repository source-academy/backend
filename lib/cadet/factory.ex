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
  alias Cadet.Course.Material
  alias Cadet.Assessments.Assessment
  alias Cadet.Assessments.Question

  def user_factory do
    %User{
      name: "John Smith",
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

  def question_factory do
    %Question{
      title: "question",
      question: %{},
      type: Enum.random([:programming, :multiple_choice]),
      assessment: build(:assessment)
    }
  end
end
