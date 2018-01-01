defmodule Cadet.Factory do
  use ExMachina.Ecto, repo: Cadet.Repo

  alias Cadet.Accounts.User

  def user_factory do
    %User{
      first_name: "John Smith",
      role: :admin
    }
  end
end
