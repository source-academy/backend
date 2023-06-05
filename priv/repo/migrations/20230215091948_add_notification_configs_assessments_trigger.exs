defmodule Cadet.Repo.Migrations.AddNotificationConfigsAssessmentsTrigger do
  use Ecto.Migration

  def up do
    execute("""
      CREATE OR REPLACE FUNCTION populate_noti_configs_from_notification_types_for_assconf() RETURNS trigger AS $$
      DECLARE
        ntype Record;
      BEGIN
        FOR ntype IN (SELECT * FROM notification_types WHERE is_autopopulated = FALSE) LOOP
          INSERT INTO notification_configs (notification_type_id, course_id, assessment_config_id, inserted_at, updated_at)
          VALUES (ntype.id, NEW.course_id, NEW.id, current_timestamp, current_timestamp);
        END LOOP;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    """)

    execute("""
      CREATE TRIGGER populate_notification_configs_on_new_assessment_config
      AFTER INSERT ON assessment_configs
      FOR EACH ROW EXECUTE PROCEDURE populate_noti_configs_from_notification_types_for_assconf();
    """)
  end

  def down do
    execute("""
      DROP TRIGGER IF EXISTS populate_notification_configs_on_new_assessment_config ON assessment_configs;
    """)

    execute("""
      DROP FUNCTION IF EXISTS populate_noti_configs_from_notification_types_for_assconf;
    """)
  end
end
