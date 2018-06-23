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
end
