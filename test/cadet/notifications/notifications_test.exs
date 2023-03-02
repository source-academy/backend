defmodule Cadet.NotificationsTest do
  use Cadet.DataCase

  alias Cadet.Notifications

  describe "notification_types" do
    test "get_notification_type!/1 returns the notification_type with given id" do
      ntype = insert(:notification_type)
      result = Notifications.get_notification_type!(ntype.id)
      assert ntype.id == result.id
    end
  end

  describe "notification_configs" do
    alias Cadet.Notifications.NotificationConfig

    @invalid_attrs %{is_enabled: nil}

    test "get_notification_config!/3 returns the notification_config with given id" do
      notification_config = insert(:notification_config)

      assert Notifications.get_notification_config!(
               notification_config.notification_type.id,
               notification_config.course.id,
               notification_config.assessment_config.id
             ).id == notification_config.id
    end

    test "get_notification_config!/3 with no assessment config returns the notification_config with given id" do
      notification_config = insert(:notification_config, assessment_config: nil)

      assert Notifications.get_notification_config!(
               notification_config.notification_type.id,
               notification_config.course.id,
               nil
             ).id == notification_config.id
    end

    test "update_notification_config/2 with valid data updates the notification_config" do
      notification_config = insert(:notification_config)
      update_attrs = %{is_enabled: true}

      assert {:ok, %NotificationConfig{} = notification_config} =
               Notifications.update_notification_config(notification_config, update_attrs)

      assert notification_config.is_enabled == true
    end

    test "update_notification_config/2 with invalid data returns error changeset" do
      notification_config = insert(:notification_config)

      assert {:error, %Ecto.Changeset{}} =
               Notifications.update_notification_config(notification_config, @invalid_attrs)

      assert notification_config.id ==
               Notifications.get_notification_config!(
                 notification_config.notification_type.id,
                 notification_config.course.id,
                 notification_config.assessment_config.id
               ).id
    end

    test "change_notification_config/1 returns a notification_config changeset" do
      notification_config = insert(:notification_config)
      assert %Ecto.Changeset{} = Notifications.change_notification_config(notification_config)
    end
  end

  describe "time_options" do
    alias Cadet.Notifications.TimeOption

    @invalid_attrs %{is_default: nil, minutes: nil}

    test "get_time_option!/1 returns the time_option with given id" do
      time_option = insert(:time_option)
      assert Notifications.get_time_option!(time_option.id).id == time_option.id
    end

    test "get_time_options_for_assessment/2 returns the time_option with given ids" do
      time_option = insert(:time_option)

      assert List.first(
               Notifications.get_time_options_for_assessment(
                 time_option.notification_config.assessment_config.id,
                 time_option.notification_config.notification_type.id
               )
             ).id == time_option.id
    end

    test "get_default_time_option_for_assessment!/2 returns the time_option with given ids" do
      time_option = insert(:time_option, is_default: true)

      assert Notifications.get_default_time_option_for_assessment!(
               time_option.notification_config.assessment_config.id,
               time_option.notification_config.notification_type.id
             ).id == time_option.id
    end

    test "create_time_option/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Notifications.create_time_option(@invalid_attrs)
    end

    test "delete_time_option/1 deletes the time_option" do
      time_option = insert(:time_option)
      assert {:ok, %TimeOption{}} = Notifications.delete_time_option(time_option)
      assert_raise Ecto.NoResultsError, fn -> Notifications.get_time_option!(time_option.id) end
    end
  end

  describe "notification_preferences" do
    alias Cadet.Notifications.NotificationPreference

    @invalid_attrs %{is_enabled: nil}

    test "get_notification_preference!/1 returns the notification_preference with given id" do
      notification_preference = insert(:notification_preference)

      assert Notifications.get_notification_preference(
               notification_preference.notification_config.notification_type.id,
               notification_preference.course_reg.id
             ).id == notification_preference.id
    end

    test "create_notification_preference/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               Notifications.create_notification_preference(@invalid_attrs)
    end

    test "update_notification_preference/2 with valid data updates the notification_preference" do
      notification_preference = insert(:notification_preference)
      update_attrs = %{is_enabled: true}

      assert {:ok, %NotificationPreference{} = notification_preference} =
               Notifications.update_notification_preference(notification_preference, update_attrs)

      assert notification_preference.is_enabled == true
    end

    test "update_notification_preference/2 with invalid data returns error changeset" do
      notification_preference = insert(:notification_preference)

      assert {:error, %Ecto.Changeset{}} =
               Notifications.update_notification_preference(
                 notification_preference,
                 @invalid_attrs
               )

      assert notification_preference.id ==
               Notifications.get_notification_preference(
                 notification_preference.notification_config.notification_type.id,
                 notification_preference.course_reg.id
               ).id
    end

    test "delete_notification_preference/1 deletes the notification_preference" do
      notification_preference = insert(:notification_preference)

      assert {:ok, %NotificationPreference{}} =
               Notifications.delete_notification_preference(notification_preference)

      assert Notifications.get_notification_preference(
               notification_preference.notification_config.notification_type.id,
               notification_preference.course_reg.id
             ) == nil
    end

    test "change_notification_preference/1 returns a notification_preference changeset" do
      notification_preference = insert(:notification_preference)

      assert %Ecto.Changeset{} =
               Notifications.change_notification_preference(notification_preference)
    end
  end

  describe "sent_notifications" do
    # alias Cadet.Notifications.SentNotification

    # import Cadet.NotificationsFixtures

    # @invalid_attrs %{content: nil}

    # test "list_sent_notifications/0 returns all sent_notifications" do
    #   sent_notification = sent_notification_fixture()
    #   assert Notifications.list_sent_notifications() == [sent_notification]
    # end

    # test "get_sent_notification!/1 returns the sent_notification with given id" do
    #   sent_notification = sent_notification_fixture()
    #   assert Notifications.get_sent_notification!(sent_notification.id) == sent_notification
    # end
  end
end
