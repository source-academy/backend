defmodule Cadet.Notifications.NotificationTypeTest do
  alias Cadet.Notifications.NotificationType
  alias Cadet.Repo

  use Cadet.ChangesetCase, entity: NotificationType

  setup do
    changeset =
      NotificationType.changeset(%NotificationType{}, %{
        name: "Notification Type 1",
        template_file_name: "template_file_1",
        is_enabled: true,
        is_autopopulated: true
      })

    {:ok, _noti_type1} = Repo.insert(changeset)

    {:ok, %{changeset: changeset}}
  end

  describe "Changesets" do
    test "valid changesets" do
      assert_changeset(
        %{
          name: "Notification Type 2",
          template_file_name: "template_file_2",
          is_enabled: false,
          is_autopopulated: true
        },
        :valid
      )
    end

    test "invalid changesets missing name" do
      assert_changeset(
        %{
          template_file_name: "template_file_2",
          is_enabled: false,
          is_autopopulated: true
        },
        :invalid
      )
    end

    test "invalid changesets missing template_file_name" do
      assert_changeset(
        %{
          name: "Notification Type 2",
          is_enabled: false,
          is_autopopulated: true
        },
        :invalid
      )
    end

    test "invalid changeset duplicate name", %{changeset: changeset} do
      {:error, changeset} = Repo.insert(changeset)

      assert changeset.errors == [
               name:
                 {"has already been taken",
                  [constraint: :unique, constraint_name: "notification_types_name_index"]}
             ]

      refute changeset.valid?
    end

    test "invalid changeset nil is_enabled" do
      assert_changeset(
        %{
          name: "Notification Type 0",
          is_enabled: nil,
          is_autopopulated: true
        },
        :invalid
      )
    end
  end
end
