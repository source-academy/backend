defmodule Cadet.NotificationsTest do
  use Cadet.DataCase

  alias Cadet.Notifications

  describe "notification_types" do
    # alias Cadet.Notifications.NotificationType

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

  describe "notification_configs" do
    # alias Cadet.Notifications.NotificationConfig

    # import Cadet.NotificationsFixtures

    # @invalid_attrs %{is_enabled: nil}

    # test "list_notification_configs/0 returns all notification_configs" do
    #   notification_config = notification_config_fixture()
    #   assert Notifications.list_notification_configs() == [notification_config]
    # end

    # test "get_notification_config!/1 returns the notification_config with given id" do
    #   notification_config = notification_config_fixture()
    #   assert Notifications.get_notification_config!(notification_config.id) == notification_config
    # end

    # test "create_notification_config/1 with valid data creates a notification_config" do
    #   valid_attrs = %{is_enabled: true}

    #   assert {:ok, %NotificationConfig{} = notification_config} = Notifications.create_notification_config(valid_attrs)
    #   assert notification_config.is_enabled == true
    # end

    # test "create_notification_config/1 with invalid data returns error changeset" do
    #   assert {:error, %Ecto.Changeset{}} = Notifications.create_notification_config(@invalid_attrs)
    # end

    # test "update_notification_config/2 with valid data updates the notification_config" do
    #   notification_config = notification_config_fixture()
    #   update_attrs = %{is_enabled: false}

    #   assert {:ok, %NotificationConfig{} = notification_config} = Notifications.update_notification_config(notification_config, update_attrs)
    #   assert notification_config.is_enabled == false
    # end

    # test "update_notification_config/2 with invalid data returns error changeset" do
    #   notification_config = notification_config_fixture()
    #   assert {:error, %Ecto.Changeset{}} = Notifications.update_notification_config(notification_config, @invalid_attrs)
    #   assert notification_config == Notifications.get_notification_config!(notification_config.id)
    # end

    # test "delete_notification_config/1 deletes the notification_config" do
    #   notification_config = notification_config_fixture()
    #   assert {:ok, %NotificationConfig{}} = Notifications.delete_notification_config(notification_config)
    #   assert_raise Ecto.NoResultsError, fn -> Notifications.get_notification_config!(notification_config.id) end
    # end

    # test "change_notification_config/1 returns a notification_config changeset" do
    #   notification_config = notification_config_fixture()
    #   assert %Ecto.Changeset{} = Notifications.change_notification_config(notification_config)
    # end
  end

  describe "time_options" do
    #   alias Cadet.Notifications.TimeOption

    #   import Cadet.NotificationsFixtures

    #   @invalid_attrs %{is_default: nil, minutes: nil}

    #   test "list_time_options/0 returns all time_options" do
    #     time_option = time_option_fixture()
    #     assert Notifications.list_time_options() == [time_option]
    #   end

    #   test "get_time_option!/1 returns the time_option with given id" do
    #     time_option = time_option_fixture()
    #     assert Notifications.get_time_option!(time_option.id) == time_option
    #   end

    #   test "create_time_option/1 with valid data creates a time_option" do
    #     valid_attrs = %{is_default: true, minutes: 42}

    #     assert {:ok, %TimeOption{} = time_option} = Notifications.create_time_option(valid_attrs)
    #     assert time_option.is_default == true
    #     assert time_option.minutes == 42
    #   end

    #   test "create_time_option/1 with invalid data returns error changeset" do
    #     assert {:error, %Ecto.Changeset{}} = Notifications.create_time_option(@invalid_attrs)
    #   end

    #   test "update_time_option/2 with valid data updates the time_option" do
    #     time_option = time_option_fixture()
    #     update_attrs = %{is_default: false, minutes: 43}

    #     assert {:ok, %TimeOption{} = time_option} = Notifications.update_time_option(time_option, update_attrs)
    #     assert time_option.is_default == false
    #     assert time_option.minutes == 43
    #   end

    #   test "update_time_option/2 with invalid data returns error changeset" do
    #     time_option = time_option_fixture()
    #     assert {:error, %Ecto.Changeset{}} = Notifications.update_time_option(time_option, @invalid_attrs)
    #     assert time_option == Notifications.get_time_option!(time_option.id)
    #   end

    #   test "delete_time_option/1 deletes the time_option" do
    #     time_option = time_option_fixture()
    #     assert {:ok, %TimeOption{}} = Notifications.delete_time_option(time_option)
    #     assert_raise Ecto.NoResultsError, fn -> Notifications.get_time_option!(time_option.id) end
    #   end

    #   test "change_time_option/1 returns a time_option changeset" do
    #     time_option = time_option_fixture()
    #     assert %Ecto.Changeset{} = Notifications.change_time_option(time_option)
    #   end
  end

  describe "notification_preferences" do
    # alias Cadet.Notifications.NotificationPreference

    # import Cadet.NotificationsFixtures

    # @invalid_attrs %{is_enable: nil}

    # test "list_notification_preferences/0 returns all notification_preferences" do
    #   notification_preference = notification_preference_fixture()
    #   assert Notifications.list_notification_preferences() == [notification_preference]
    # end

    # test "get_notification_preference!/1 returns the notification_preference with given id" do
    #   notification_preference = notification_preference_fixture()
    #   assert Notifications.get_notification_preference!(notification_preference.id) == notification_preference
    # end

    # test "create_notification_preference/1 with valid data creates a notification_preference" do
    #   valid_attrs = %{is_enable: true}

    #   assert {:ok, %NotificationPreference{} = notification_preference} = Notifications.create_notification_preference(valid_attrs)
    #   assert notification_preference.is_enable == true
    # end

    # test "create_notification_preference/1 with invalid data returns error changeset" do
    #   assert {:error, %Ecto.Changeset{}} = Notifications.create_notification_preference(@invalid_attrs)
    # end

    # test "update_notification_preference/2 with valid data updates the notification_preference" do
    #   notification_preference = notification_preference_fixture()
    #   update_attrs = %{is_enable: false}

    #   assert {:ok, %NotificationPreference{} = notification_preference} = Notifications.update_notification_preference(notification_preference, update_attrs)
    #   assert notification_preference.is_enable == false
    # end

    # test "update_notification_preference/2 with invalid data returns error changeset" do
    #   notification_preference = notification_preference_fixture()
    #   assert {:error, %Ecto.Changeset{}} = Notifications.update_notification_preference(notification_preference, @invalid_attrs)
    #   assert notification_preference == Notifications.get_notification_preference!(notification_preference.id)
    # end

    # test "delete_notification_preference/1 deletes the notification_preference" do
    #   notification_preference = notification_preference_fixture()
    #   assert {:ok, %NotificationPreference{}} = Notifications.delete_notification_preference(notification_preference)
    #   assert_raise Ecto.NoResultsError, fn -> Notifications.get_notification_preference!(notification_preference.id) end
    # end

    # test "change_notification_preference/1 returns a notification_preference changeset" do
    #   notification_preference = notification_preference_fixture()
    #   assert %Ecto.Changeset{} = Notifications.change_notification_preference(notification_preference)
    # end
  end
end
