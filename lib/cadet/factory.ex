defmodule Cadet.Factory do
  use ExMachina.Ecto, repo: Cadet.Repo

  alias Cadet.Accounts.User
  alias Cadet.Accounts.Authorization
  alias Cadet.Course.Announcement

  def user_factory do
    %User{
      first_name: "John Smith",
      role: :admin
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
end
