defmodule Cadet.NotificationsTest do
  use Cadet.DataCase

  alias Cadet.Notifications
  alias Cadet.Notifications.{NotificationConfig, NotificationPreference, TimeOption}

  describe "notification_types" do
    test "get_notification_type!/1 returns the notification_type with given id" do
      ntype = insert(:notification_type)
      result = Notifications.get_notification_type!(ntype.id)
      assert ntype.id == result.id
    end
  end

  describe "notification_configs" do
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
    @invalid_attrs %{is_enabled: nil}

    test "get_notification_preference!/1 returns the notification_preference with given id" do
      notification_type = insert(:notification_type, name: "get_notification_preference!/1")
      notification_config = insert(:notification_config, notification_type: notification_type)

      notification_preference =
        insert(:notification_preference, notification_config: notification_config)

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
      notification_type =
        insert(:notification_type, name: "update_notification_preference/2 valid")

      notification_config = insert(:notification_config, notification_type: notification_type)

      notification_preference =
        insert(:notification_preference, notification_config: notification_config)

      update_attrs = %{is_enabled: true}

      assert {:ok, %NotificationPreference{} = notification_preference} =
               Notifications.update_notification_preference(notification_preference, update_attrs)

      assert notification_preference.is_enabled == true
    end

    test "update_notification_preference/2 with invalid data returns error changeset" do
      notification_type =
        insert(:notification_type, name: "update_notification_preference/2 invalid")

      notification_config = insert(:notification_config, notification_type: notification_type)

      notification_preference =
        insert(:notification_preference, notification_config: notification_config)

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
      notification_type = insert(:notification_type, name: "delete_notification_preference/1")
      notification_config = insert(:notification_config, notification_type: notification_type)

      notification_preference =
        insert(:notification_preference, notification_config: notification_config)

      assert {:ok, %NotificationPreference{}} =
               Notifications.delete_notification_preference(notification_preference)

      assert Notifications.get_notification_preference(
               notification_preference.notification_config.notification_type.id,
               notification_preference.course_reg.id
             ) == nil
    end

    test "change_notification_preference/1 returns a notification_preference changeset" do
      notification_type = insert(:notification_type, name: "change_notification_preference/1")
      notification_config = insert(:notification_config, notification_type: notification_type)

      notification_preference =
        insert(:notification_preference, notification_config: notification_config)

      assert %Ecto.Changeset{} =
               Notifications.change_notification_preference(notification_preference)
    end
  end

  describe "sent_notifications" do
    alias Cadet.Notifications.SentNotification

    setup do
      course = insert(:course)
      course_reg = insert(:course_registration, course: course)
      {:ok, course_reg: course_reg}
    end

    test "create_sent_notification/1 with valid data creates a sent_notification",
         %{course_reg: course_reg} do
      assert {:ok, %SentNotification{}} =
               Notifications.create_sent_notification(course_reg.id, "test content")
    end

    test "create_sent_notification/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               Notifications.create_sent_notification(nil, "test content")
    end

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
