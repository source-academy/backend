# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Cadet.Repo.insert!(%Cadet.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
import Cadet.Factory

if Application.get_env(:cadet, :environment) == :dev do
  seeded_users = [
    %{
      name: "TestStudent",
      nusnet_id: "E012345",
      role: :student
    },
    %{
      name: "TestStaff",
      nusnet_id: "E123456",
      role: :staff
    },
    %{
      name: "TestAdmin",
      nusnet_id: "E234567",
      role: :admin
    }
  ]

  Enum.each(seeded_users, fn attr ->
    user = insert(:user, attr)

    insert(:email, %{
      uid: attr.name <> "@test.com",
      token: Pbkdf2.hash_pwd_salt("password"),
      user: user
    })
  end)
end
