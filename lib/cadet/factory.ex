defmodule Cadet.Factory do
  use ExMachina.Ecto, repo: Cadet.Repo

  alias Cadet.Accounts.User
  alias Cadet.Accounts.Authorization
  alias Cadet.Course.Announcement
  alias Cadet.Course.Point

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
end
