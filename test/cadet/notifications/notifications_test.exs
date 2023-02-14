defmodule Cadet.NotificationsTest do
  use Cadet.DataCase

  alias Cadet.Notifications

  describe "notification_types" do
    alias Cadet.Notifications.NotificationType

    # import Cadet.NotificationsFixtures

    # @invalid_attrs %{is_autopopulated: nil, is_enabled: nil, name: nil, template_file_name: nil}

    # test "list_notification_types/0 returns all notification_types" do
    #   notification_type = notification_type_fixture()
    #   assert Notifications.list_notification_types() == [notification_type]
    # end

    # test "get_notification_type!/1 returns the notification_type with given id" do
    #   notification_type = notification_type_fixture()
    #   assert Notifications.get_notification_type!(notification_type.id) == notification_type
    # end

    # test "create_notification_type/1 with valid data creates a notification_type" do
    #   valid_attrs = %{is_autopopulated: true, is_enabled: true, name: "some name", template_file_name: "some template_file_name"}

    #   assert {:ok, %NotificationType{} = notification_type} = Notifications.create_notification_type(valid_attrs)
    #   assert notification_type.is_autopopulated == true
    #   assert notification_type.is_enabled == true
    #   assert notification_type.name == "some name"
    #   assert notification_type.template_file_name == "some template_file_name"
    # end

    # test "create_notification_type/1 with invalid data returns error changeset" do
    #   assert {:error, %Ecto.Changeset{}} = Notifications.create_notification_type(@invalid_attrs)
    # end

    # test "update_notification_type/2 with valid data updates the notification_type" do
    #   notification_type = notification_type_fixture()
    #   update_attrs = %{is_autopopulated: false, is_enabled: false, name: "some updated name", template_file_name: "some updated template_file_name"}

    #   assert {:ok, %NotificationType{} = notification_type} = Notifications.update_notification_type(notification_type, update_attrs)
    #   assert notification_type.is_autopopulated == false
    #   assert notification_type.is_enabled == false
    #   assert notification_type.name == "some updated name"
    #   assert notification_type.template_file_name == "some updated template_file_name"
    # end

    # test "update_notification_type/2 with invalid data returns error changeset" do
    #   notification_type = notification_type_fixture()
    #   assert {:error, %Ecto.Changeset{}} = Notifications.update_notification_type(notification_type, @invalid_attrs)
    #   assert notification_type == Notifications.get_notification_type!(notification_type.id)
    # end

    # test "delete_notification_type/1 deletes the notification_type" do
    #   notification_type = notification_type_fixture()
    #   assert {:ok, %NotificationType{}} = Notifications.delete_notification_type(notification_type)
    #   assert_raise Ecto.NoResultsError, fn -> Notifications.get_notification_type!(notification_type.id) end
    # end

    # test "change_notification_type/1 returns a notification_type changeset" do
    #   notification_type = notification_type_fixture()
    #   assert %Ecto.Changeset{} = Notifications.change_notification_type(notification_type)
    # end
  end
end
