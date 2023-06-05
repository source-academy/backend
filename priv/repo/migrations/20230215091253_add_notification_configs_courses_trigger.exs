defmodule Cadet.Repo.Migrations.AddNotificationConfigsCoursesTrigger do
  use Ecto.Migration

  def up do
    execute("""
      CREATE OR REPLACE FUNCTION populate_noti_configs_from_notification_types_for_course() RETURNS trigger AS $$
      DECLARE
        ntype Record;
      BEGIN
        FOR ntype IN (SELECT * FROM notification_types WHERE is_autopopulated = TRUE) LOOP
          INSERT INTO notification_configs (notification_type_id, course_id, assessment_config_id, inserted_at, updated_at)
          VALUES (ntype.id, NEW.id, NULL, current_timestamp, current_timestamp);
        END LOOP;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    """)

    execute("""
      CREATE TRIGGER populate_notification_configs_on_new_course
      AFTER INSERT ON courses
      FOR EACH ROW EXECUTE PROCEDURE populate_noti_configs_from_notification_types_for_course();
    """)
  end

  def down do
    execute("""
      DROP TRIGGER IF EXISTS populate_notification_configs_on_new_course ON courses;
    """)

    execute("""
      DROP FUNCTION IF EXISTS populate_noti_configs_from_notification_types_for_course;
    """)
  end
end
